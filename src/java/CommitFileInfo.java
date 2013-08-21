
import java.io.File;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;
import org.json.simple.JSONArray;
import org.json.simple.JSONObject;
import org.neo4j.cypher.javacompat.ExecutionEngine;
import org.neo4j.cypher.javacompat.ExecutionResult;
import org.neo4j.graphdb.Direction;
import org.neo4j.graphdb.Node;
import org.neo4j.graphdb.Relationship;
import org.neo4j.helpers.collection.IteratorUtil;

/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */

/**
 *
 * @author josericardo
 */
public class CommitFileInfo {
    
    public static class Vector2 {
        public float x;
        public float y;
    }
    
    private String repoName;
    private List<String> files = new ArrayList<>();
    private List<String> commits = new ArrayList<>();
    private int file_commit_mat[][];
    private Vector2 sup_conf_mat_file[][]; 
    private float minConfidenceVal;
    private float minSupportVal;
    
    
    
    public CommitFileInfo(String _repoName){
        repoName = _repoName;
    }
    
    private void FillCommitAndFiles(ExecutionEngine _engine){
        
        ExecutionResult res = _engine.execute("start n = node(*)\n"
                + "MATCH (c)-[r:REPOSITORY]->(n)\n"
                + "where c._type = \"COMMIT\" and n._type=\"REPOSITORY\"\n and n.fullname=\"" + repoName + "\""
                + "return c ORDER BY c.date ASC");

        Iterator<Node> node_commits = res.columnAs("c");

        // Create the array of committs
        for (Node node_commit : IteratorUtil.asIterable(node_commits)) {

            if (!commits.contains(node_commit.getProperty("hash").toString())) {
                commits.add(node_commit.getProperty("hash").toString());
            }


            // File relationships
            Iterable<Relationship> commits_files_r =
                    node_commit.getRelationships(QiViProcessing.RelTypes.CHANGED, Direction.OUTGOING);

            for (Relationship commit_files_r : commits_files_r) {
                Node file = commit_files_r.getEndNode();

                String file_token = file.getProperty("token").toString();

                int lastSlash = file_token.lastIndexOf(File.separatorChar);
                String filename = file_token.substring(lastSlash + 1);
                int last_dot = filename.lastIndexOf('.');
                String extension = filename.substring(last_dot + 1);

                if (extension.compareTo("java") == 0) {

                    if (!files.contains(filename)) {
                        files.add(filename);
                    }
                }
            }
        }
    }
    
    private void ProcessMatrix(ExecutionEngine _engine){
        
        file_commit_mat = new int[commits.size()][files.size()];
        
        ExecutionResult res = _engine.execute("start n = node(*)\n"
                + "MATCH (c)-[r:REPOSITORY]->(n)\n"
                + "where c._type = \"COMMIT\" and n._type=\"REPOSITORY\"\n and n.fullname=\"" + repoName + "\""
                + "return c ORDER BY c.date ASC");


        Iterator<Node> node_commits = res.columnAs("c");
        
        boolean first = true;

        for (Node node_commit : IteratorUtil.asIterable(node_commits)) {
            
            if (first == true){ first = false; continue; }
            
            int current_commit[] = file_commit_mat[commits.indexOf(node_commit.getProperty("hash"))];


            // File relationships
            Iterable<Relationship> commits_files_r =
                    node_commit.getRelationships(QiViProcessing.RelTypes.CHANGED, Direction.OUTGOING);

            for (Relationship commit_files_r : commits_files_r) {
                Node file = commit_files_r.getEndNode();

                String file_token = file.getProperty("token").toString();

                int lastSlash = file_token.lastIndexOf(File.separatorChar);
                String filename = file_token.substring(lastSlash + 1);
                int last_dot = filename.lastIndexOf('.');
                String extension = filename.substring(last_dot + 1);

                if (extension.compareTo("java") == 0) {
                    current_commit[files.indexOf(filename)] = 1;
                }
            }
        }
        
        
        sup_conf_mat_file = new Vector2[files.size()][files.size()];
    }
    
    private void ProcessSupportAndConfidence(){
        
        sup_conf_mat_file = new Vector2[files.size()][files.size()];
        
        // Support
        minSupportVal = 100;
        
        for (int j = 0; j < sup_conf_mat_file.length; j++) {
            
            for (int i = 0; i < sup_conf_mat_file[j].length; i++) {
                
                sup_conf_mat_file[i][j] = new Vector2();

                for (int[] _commit : file_commit_mat) {

                    if (_commit[i] == 1 && _commit[j] == 1) {
                        sup_conf_mat_file[i][j].x += 1;
                    }


                }
                sup_conf_mat_file[i][j].x /= (commits.size() - 1);
                
                if (sup_conf_mat_file[i][j].x > 0 && sup_conf_mat_file[i][j].x < minSupportVal)
                    minSupportVal = sup_conf_mat_file[i][j].x;
            }
        }
        

        
        // Confidence
        minConfidenceVal = 100;
        
        for (int j = 0; j < sup_conf_mat_file.length; j++) {
            for (int i = 0; i < sup_conf_mat_file[j].length; i++) {
                for (int[] _commit : file_commit_mat) {
                    sup_conf_mat_file[j][i].y = sup_conf_mat_file[j][i].x
                            / sup_conf_mat_file[j][j].x;
                    
                    if (sup_conf_mat_file[j][i].y > 0 && sup_conf_mat_file[j][i].y < minConfidenceVal)
                        minConfidenceVal = sup_conf_mat_file[j][i].y;
                }
            }
        }
    }
    
    public void Process(ExecutionEngine _engine){
        
        FillCommitAndFiles(_engine);
        ProcessMatrix(_engine);
        ProcessSupportAndConfidence();
    }
    

    
    public String Serialize(){
        
        // Write all nodes
        JSONArray jsonNodes = new JSONArray();
        for (int i = 0; i < files.size(); i++){
            JSONObject jsonNode = new JSONObject();
            jsonNode.put("name", files.get(i));
            jsonNode.put("id", files.get(i));
            jsonNodes.add(jsonNode);
        }
        

        
        // Write all relationships
        JSONArray jsonLinks = new JSONArray();
        for (int j = 0; j < sup_conf_mat_file.length; j++) {
            for (int i = 0; i < sup_conf_mat_file[j].length; i++) {
                
                if (i == j) continue;
                
                JSONObject jsonLink = new JSONObject();
                jsonLink.put("source", files.get(j));
                jsonLink.put("target", files.get(i));
                jsonLink.put("support", sup_conf_mat_file[j][i].x);
                jsonLink.put("confidence", sup_conf_mat_file[j][i].y);
                jsonLinks.add(jsonLink);
            }


        }
        
        JSONObject finalJson = new JSONObject();
        finalJson.put("nodes", jsonNodes);
        finalJson.put("links", jsonLinks);
        finalJson.put("minConf", minConfidenceVal);
        finalJson.put("minSup", minSupportVal);
        
        return finalJson.toJSONString();
    }
}
