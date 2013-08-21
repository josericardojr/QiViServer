<%-- 
    Document   : index
    Created on : Aug 6, 2013, 12:30:25 PM
    Author     : josericardo
--%>

<%@page contentType="text/html" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<script src="http://d3js.org/d3.v3.js"></script>
<style>

path.link {
  fill: none;
  stroke: #666;
  stroke-width: 1.5px;
}

circle {
  fill: #ccc;
  stroke: #fff;
  stroke-width: 1.5px;
}

text {
  fill: #000;
  font: 10px sans-serif;
  pointer-events: none;
}

</style>
<html>
    <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
        <title>JSP Page</title>
        <link href="css/bootstrap-responsive.css" rel="stylesheet">
        <link rel="stylesheet" href="css/bootstrap.css">    
        <script src="js/jquery-1.8.2.min.js"></script>
        <script src="js/bootstrap.min.js"></script>
        <script src="js/sylvester.src.js"></script>
        <script src="js/glUtils.js"></script>
        <script src="js/smartslider.js" type="text/javascript"></script>
        <link href="css/smartslider.css" rel="stylesheet" type="text/css">
        <link rel="stylesheet" href="http://code.jquery.com/ui/1.10.3/themes/smoothness/jquery-ui.css" />
        <script src="http://code.jquery.com/ui/1.10.3/jquery-ui.js"></script>
      
        <script type="text/javascript">
            var jsonData;
            var nodes = {};
            var height = 400, width = 800;
            var force;
            var svg; 
            var currentClass;
            var svgGraphGroup;
            var svgMatrixSideText;
            var svgMatrixTopText;
            var svgMatrixData;
            var minConf = 0;
            
            function TreeGeneration()
            {
                var options = $("#fileoption");
                
                for (var i = 0; i < jsonData.nodes.length; i++){          
                    nodes[jsonData.nodes[i].id] = {name: jsonData.nodes[i].name, my_idx : i};
                    options.append($("<option />").val(jsonData.nodes[i].id).text(jsonData.nodes[i].name));
                }
                    
                    
                force = d3.layout.force()
                    .linkDistance(60)
                    .charge(-300)
                    .size([width, height]);
            
                svg = d3.select("#mydiv").append("svg")
                    .attr("width", width)
                    .attr("height", height);
            
                var svg2 = d3.select("#mydiv2").append("svg")
                    .attr("width", width)
                    .attr("height", height);
            
                svgMatrixSideText = svg2.append("g")
                    .attr("transform", "translate(0, 142)");
                svgMatrixTopText = svg2.append("g")
                    .attr("transform", "translate(112, 125)");
                svgMatrixData = svg2.append("g")
                    .attr("transform", "translate(100, 130)");
            
                svgGraphGroup = svg.append("g");
        
                svgGraphGroup.append("svg:defs").selectAll("marker")
                    .data(["end"])
                    .enter()
                    .append("svg:marker")
                        .attr("id", String)
                        .attr("viewBox", "0 -5 10 10")
                        .attr("refX", 15)
                        .attr("refY", -1.5)
                        .attr("markerWidth", 6)
                        .attr("markerHeight", 6)
                        .attr("orient", "auto")
                    .append("svg:path")
                        .attr("d", "M0,-5L10,0L0,5");
                
                console.error(svgMatrixSideText);
            
    
                Update(jsonData.minConf, jsonData.minSup);
            }
            
            function Update(conf, supp)
            {
                var _nodes = {};
          
                var confPerc = conf / 100.0;
                var supPerc = supp / 100.0;


                var links = new Array();

                jsonData.links.forEach(function(link)
                {
                    if ((parseFloat(link.support) >= supPerc) && 
                            (parseFloat(link.confidence) >= confPerc)){// && (link.source == currentClass)){

                        var lnk = {};
                        _nodes[link.source] = nodes[link.source];
                        _nodes[link.target] = nodes[link.target];
                        lnk.source = _nodes[link.source];
                        lnk.target = _nodes[link.target] ;
                        lnk.support = parseFloat(link.support);
                        lnk.confidence = parseFloat(link.confidence);
                        links.push(lnk);
                    }
                });
          
                force.nodes(d3.values(_nodes));
                force.links(links);
                
                var _nodes_ = svgGraphGroup.selectAll('g.node').data(force.nodes(), function(d){
                        return d.name;
                    });
                    
                var _newNodes_ = _nodes_
                    .enter()
                        .append('svg:g')
                        .attr('class', 'node')
                        .call(force.drag);
                
                _newNodes_.append("svg:text")
                    .attr("x", 12)
                    .attr("dy", ".35em")
                    .text(function(d) { return d.name; });
                
                var _circles = _newNodes_
                    .append('svg:circle')
                    .attr('r', 5);
            
                svgGraphGroup.selectAll("g.node").data(force.nodes(), function(d){
                    return d.name;
                }).exit().remove();
            
            
                svgGraphGroup.append("svg:g");
                
                var path = svgGraphGroup.selectAll("path.link")
                    .data(force.links());
                    
                    
                var _new_path = path.enter().append("svg:path")
                    .attr("class", "link")
                    .attr("marker-end", "url(#end)")
                    .attr("d", function(d) {
                            var dx = d.target.x - d.source.x,
                            dy = d.target.y - d.source.y,
                            dr = Math.sqrt(dx * dx + dy * dy);
                            return "M" + 
                            d.source.x + "," + 
                            d.source.y + "A" + 
                            dr + "," + dr + " 0 0,1 " + 
                            d.target.x + "," + 
                            d.target.y;
                        });
                    
                svgGraphGroup.selectAll("path.link").data(force.links()).exit().remove();
      
      
      
      
                  // Matrix update

            svgMatrixSideText.selectAll("g.text").remove();
            svgMatrixTopText.selectAll("g.text").remove();
            
            svgMatrixSideText.selectAll("g.text").data(force.nodes(), function(d){
                return d.name;
            }).enter()
                .append("svg:g")
                    .attr("class", "text")
                .append("svg:text")
                    .attr("x", "0")
                    .attr("y", function(d, index){
                        return index*33;
                    })
                    .text(function(d){ return d.name;});
            
            
            svgMatrixTopText.selectAll("g.text").data(force.nodes(), function(d){
                return d.name;
            }).enter()
                .append("svg:g")
                    .attr("class", "text")
                .append("svg:text")
                    .attr("transform", function(d, index){
                        d.my_idx = index;
                        return "translate(" + (index * 33) + ", 0) rotate(270)"; 
                    })
                    .text(function(d){ return d.name;});
                
                
            //svgMatrixSideText.selectAll("g.text").data(force.nodes()).exit().remove();   
            //svgMatrixTopText.selectAll("g.text").data(force.nodes()).exit().remove();
            
            svgMatrixData.selectAll("text.txclass").remove();
            svgMatrixData.selectAll("rect.rectangle").remove();
            
            var dt = svgMatrixData.selectAll("rect.rectangle").data(force.links())
                .enter();
        
            
                dt.append("svg:rect")
                .attr("width", "32")
                .attr("height", "32")
                .attr("class", "rectangle")
                .attr("style", "fill: ff0000;")
                .attr("x", function(link){
                    return (link.source.my_idx * 32);
                })
                .attr("y", function(link){
                    return (link.target.my_idx * 32);
                })
                
            dt.append("svg:text")
                .attr("class", "txclass")
                    .text(function(link){ return link.confidence.toFixed(2); })
                .attr("x", function(link){
                    return (link.source.my_idx * 32) + 1;
                })
                .attr("y", function(link){
                    return (link.target.my_idx * 32) + 14;
                })
                        .attr("style", "color: white; font-size: 9px;");
                
                //svgMatrixData.selectAll("rect.rectangle").data(force.links())
                //.exit().remove();
            
        
                force.on("tick", function(){
                    path.attr("d", function(d) {
                        var dx = d.target.x - d.source.x,
                        dy = d.target.y - d.source.y,
                        dr = Math.sqrt(dx * dx + dy * dy);
                        return "M" + 
                        d.source.x + "," + 
                        d.source.y + "A" + 
                        dr + "," + dr + " 0 0,1 " + 
                        d.target.x + "," + 
                        d.target.y;
                    });

                    _nodes_
                        .attr("transform", function(d) { 
                            return "translate(" + d.x + "," + d.y + ")"; });
                    })
                    .start();
            
            
            
 
      }
      
      
      $(document).ready(function() {
      
            $( "#slider1" ).slider({ min: 0.0, max : 100.0, step : 0.5, change : function(event, ui){
                var conf = $( "#slider1" ).slider("value"); 
                var sup =  $( "#slider2" ).slider("value");
                Update(conf, sup);
            }});
            

            $( "#slider2" ).slider({ min: 0.0, max : 100.0, step : 0.5, change : function(event, ui){
                var conf = $( "#slider1" ).slider("value"); 
                var sup =  $( "#slider2" ).slider("value");
                Update(conf, sup);
            }});
        
              $("#fileoption").change(function(){
                currentClass = $("#fileoption").val(); 
                var conf = $( "#slider1" ).slider("value"); 
                var sup =  $( "#slider2" ).slider("value");
                Update(conf, sup);
            });  
                                          
            //setupGL();
        

      });
      

      </script>
  
    </head>
    <body>
        <div class="container">
            <!-- Main hero unit for a primary marketing message or call to action -->
          <div class="hero-unit">
              <h1>Qivi<sup><font color="#10A4DB">GH</font></sup></h1><br>
              <p>Explore your projects on Github</p>
              <p><a id="btn_Start" class="btn btn-primary btn-large">&nbsp;&nbsp;&nbsp; Start &raquo; &nbsp;&nbsp;&nbsp;</a></p>
              <<select id="fileoption">
                      
                  </select>
             
          </div>
       </div>
        
        <div class="container">
            <div class="hero-unit">
                <div id="mydiv"></div>
                <div id="mydiv2"></div>
            </div>          
        </div>
           <!-- <div style="width: 690px; float: left; padding: 20px;">
                 <div style="position: relative">
                    <div id="smart-slider"></div>
                    <div id="text" style="clear:both; text-align:center;width:200px;"></div>
                 </div>
            </div> -->
            <div style="float: left;">
                <div style="float: left;margin-left: 30px"> Support </div>
                <div id="slider1" style="margin-left: 80px; width: 200px; float: left;;" ></div>
                 <div style="float: left;margin-left: 30px"> Confidence </div>
                <div id="slider2" style="margin-left: 50px; width: 200px; float: left;;" ></div>
            </div>
    </body>
   
    
    
        <!-- Le javascript
    ================================================== -->
    <!-- Placed at the end of the document so the pages load faster -->

    <script>
        


  
      $('#btn_Start').click(function(){
          var posting = $.post("http://localhost:8080/QiViServer/QiViProcessing",
            {"username":"josericardo"});
            
          
          posting.done(function(data){
            jsonData = data;
              console.log(jsonData.minConf);
              console.log(jsonData.minSup);

            $( "#slider2" ).slider( "option", "min", (jsonData.minConf * 100.0) );
            $( "#slider2" ).slider( "option", "step", ((1 - jsonData.minConf) * 100.0) / 20.0 );
            $( "#slider1" ).slider( "option", "min", (jsonData.minSup * 100.0) );
            $( "#slider1" ).slider( "option", "step", ((1 - jsonData.minSup) * 100.0) / 20.0 );
            TreeGeneration();
          });

      });
    </script>
  </body>
</html>
