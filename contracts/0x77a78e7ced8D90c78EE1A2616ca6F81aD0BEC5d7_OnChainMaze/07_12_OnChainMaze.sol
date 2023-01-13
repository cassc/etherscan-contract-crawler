// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;
import "erc721a/contracts/ERC721A.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
contract OnChainMaze is DefaultOperatorFilterer, ERC721A, ReentrancyGuard, Ownable{
  uint256 public MAX_COLLECTION_SIZE=1024;
  uint256 public mintPrice=0.00256 ether;
  uint256 public maxMintPerWallet=2;
  string[][] palettes = [
      ["#144272", "#0A2647", "#FB5607", "#FBF8CC"], // Blue
      ["#3C2A21", "#1A120B", "#FF006E", "#B9FBC0"], // Brown
      ["#6D67E4", "#453C67", "#FFBE0B", "#FFCFD2"], // Blue
      ["#810CA8", "#2D033B", "#FFBE0B", "#98F5E1"], // Purple
      ["#3B185F", "#00005C", "#FF006E", "#FFD6A5"], // Purple + blue
      ["#282A3A", "#000000", "#3A86FF", "#BDB2FF"], // Gray
      ["#624F82", "#3F3B6C", "#FB5607", "#FFFFFC"], // purple
      ["#150050", "#000000", "#FFBE0B", "#CAFFBF"], // Blue
      ["#562B08", "#182747", "#FB5607", "#8EECF5"], // Blue + brown
      ["#553939", "#472D2D", "#8338EC", "#FFD6A5"], // Brown
      ["#51557E", "#1B2430", "#FF006E", "#FFADAD"]  // Blue
  ];
  uint256[] widths = [32, 64, 48, 80];
  uint256[] heights = [32, 64, 48, 80];
  uint256[] fogSizes = [4, 8, 16, 11, 13, 15, 17];

  constructor() ERC721A("OnChainMaze", "OCM") {
  }

  function mint(uint256 quantity) external payable{
      // Mint price: 0.00256, collection size 1024, max mint 2.
      require(totalSupply() + quantity <= MAX_COLLECTION_SIZE, "Reached max supply");
      require(_numberMinted(msg.sender) + quantity <= maxMintPerWallet, "Max 2 mint per wallet!");
      require(quantity * mintPrice <= msg.value, "Funds not enough.");
      /*
         The funds will be used to deploy the 3D maze (should be the first on-chain 3d game!) contract on Ethereum.
         256 holders (screenshot + raffle tbd) will get an airdrop of the 3D maze with 0.01024 eth mint price, total supply 1024.
         The game is almost done but still needs some debuging + beautify + **code compression**.
         ETA 2023/01/20.
         It cost already 2 eth to deploy the contract so far... Really needs your help.
      */
      _safeMint(msg.sender, quantity);
  }

  struct Maze {
      bool passHint;
      bool lightOut;
      string hintColor;
      string wallColor;
      string cellColor;
      string startColor;
      string endColor;
      string fogColor;
      uint256 width;
      uint256 height;
      uint256 fogSize;
  }

  function random(string memory input) internal pure returns (uint256) {
      return uint256(keccak256(abi.encodePacked(input)));
  }

  function randomRange(uint256 tokenId, string memory keyPrefix, uint256 lower, uint256 upper) internal pure returns (uint256) {
      uint256 rand = random(string(abi.encodePacked(keyPrefix, Strings.toString(tokenId))));
      return (rand % (upper - lower)) + lower;
  }

  function genMaze(uint256 tokenId) public view returns (Maze memory){
      Maze memory m;
      string[] memory palette = palettes[randomRange(tokenId, "Palette", 0, palettes.length)];
      m.passHint = (randomRange(tokenId, "passHint", 0, 2) == 1) ? true : false;
      m.lightOut = (randomRange(tokenId, "lightOut", 0, 2) == 1) ? true : false;
      m.fogColor = m.lightOut ? palette[0] : "#000";
      m.wallColor = palette[1];
      m.hintColor = m.passHint ? palette[2] : "#000";
      m.cellColor = palette[3];
      m.startColor = "#000000";
      m.endColor = palette[2];
      m.width = widths[randomRange(tokenId, "width", 0, 4)];
      m.height = heights[randomRange(tokenId, "height", 0, 4)];
      m.fogSize = fogSizes[randomRange(tokenId, "fogSize", 0, 7)];
      return m;
  }
  
  function property(Maze memory m) public pure returns (string memory){
      string memory _property = "";
      if(m.passHint){
          _property = string(abi.encodePacked(_property, 
                                              '{"trait_type":"Hint?","value":"Yes"}, {"trait_type":"Hint Color","value":"', m.hintColor, '"},'
                                             ));
      }
      else{
          _property = string(abi.encodePacked(_property, '{"trait_type":"Hint?","value":"None"},'));
      }
      if(m.lightOut){
          _property = string(abi.encodePacked(_property, '{"trait_type":"Fog","value":"Yes"},{"trait_type":"Fog Color","value":"', m.fogColor, '"},{"display_type":"number","trait_type":"Fog size","value":', Strings.toString(m.fogSize), '},'));
      }
      else{
          _property = string(abi.encodePacked(_property, '{"trait_type":"Fog","value":"None"},'));
      }
      _property = string(abi.encodePacked(
          _property,
          '{"trait_type":"Wall Color","value":"', m.wallColor, '"},',
          '{"trait_type":"Cell Color","value":"', m.cellColor, '"},'
      )
                        );
      _property = string(abi.encodePacked(
          _property,
          '{"trait_type":"Start Color","value":"', m.startColor, '"},',
          '{"trait_type":"End Color","value":"', m.endColor, '"},'
          )
                        );
      _property = string(abi.encodePacked(
          _property,
          '{"display_type":"number","trait_type":"Width","value":', Strings.toString(m.width), '},',
          '{"display_type":"number","trait_type":"Height","value":', Strings.toString(m.height), '}'
          )
      );
      return _property;
  }
  function animatedURI(Maze memory m) public pure returns (string memory){
      string memory head = "<!DOCTYPE html><html lang='en' > <head> <meta charset='UTF-8'> <script> var w=";
      string memory tail = " ** 2; </script><style>body { width: 100%; height: 100%;background-color: #555;}canvas {position: absolute;top: 0%;left: 0%; width: 100vmin; height: 100vmin;box-shadow: 0 0 2px #000;}#win {position: absolute;top: 0%;left: 0%;background-color: rgba(0,0,0,.8);text-align: center;width: 100vmin;height: 100vmin;color: #eee;opacity: 0;display: none;transition: opacity .5s;}#win.showing {display: inline-block;opacity: 1;}#win, input, button {font: 20px Helvetica;}input {width: 40px;}button {padding: 8px;}</style> </head> <body><canvas id=c></canvas><div id=win class=showing><p><button id=beginButton>Start</button></p></div><script>var s=c.width=c.height=512,finish=!1,ctx=c.getContext('2d'),maze=[],dirs=[{x:-2,y:0},{x:0,y:-2},{x:2,y:0},{x:0,y:2}],goal={},passed=[];function genMaze(){maze.length=0,passed.length=0,finish=!1;for(var e=0;e<w;++e){maze.push([]),passed.push([]);for(var a=0;a<h;++a)maze[e].push(0),passed[e].push(!1)}var s={x:1,y:1},r=[],i={i:0,t:s};maze[1][1]=1,passed[1][1]=1;do{var n=[{x:s.x+dirs[0].x,y:s.y+dirs[0].y,o:0},{x:s.x+dirs[1].x,y:s.y+dirs[1].y,o:1},{x:s.x+dirs[2].x,y:s.y+dirs[2].y,o:2},{x:s.x+dirs[3].x,y:s.y+dirs[3].y,o:3}].filter(function(e){return 0<e.x&&e.x<w&&0<e.y&&e.y<h&&0===maze[e.x][e.y]})}while(0<n.length?(r.push(s),n=n[Math.random()*n.length|0],maze[(s.x+n.x)/2][(s.y+n.y)/2]=1,maze[(s=n).x][s.y]=1):(i.i<r.length&&(i.i=r.length,i.t=s),r.pop(),s=r[r.length-1]),0<r.length);goal=i.t}function renderMaze(){ctx.fillStyle='#222',ctx.fillRect(0,0,s,s);var e=Math.min(s/w,s/h);ctx.translate(s/2-w*e/2,s/2-h*e/2);for(var a=0;a<w;++a)for(var r=0;r<h;++r)ctx.fillStyle=maze[a][r]?cellColor:wallColor,ctx.fillStyle=passed[a][r]&&passHint?hintColor:ctx.fillStyle,ctx.fillStyle=!lightOut||finish||Math.abs(a-player.x)**2+Math.abs(r-player.y)**2<fogSize?ctx.fillStyle:fogColor,ctx.fillRect(a*e-.5,r*e-.5,e+1,e+1);ctx.fillStyle=endColor,ctx.fillRect(goal.x*e-e/2,goal.y*e-e/2,2*e,2*e),ctx.fillStyle=startColor,ctx.fillRect(player.x*e+e/4,player.y*e+e/4,e/2,e/2),ctx.translate(-(s/2-w*e/2),-(s/2-h*e/2))}var keys=[{l:[37,72,65],pressed:!1},{l:[38,75,87],pressed:!1},{l:[39,76,68],pressed:!1},{l:[40,74,83],pressed:!1}],lastInput=Date.now(),player={x:1,y:1};function anim(){window.requestAnimationFrame(anim),keys.map(function(e,a){e.pressed&&20<Date.now()-lastInput&&(e=player.x+dirs[a].x/2,a=player.y+dirs[a].y/2,maze[e][a])&&(player.x=e,player.y=a,passed[e][a]=!0,lastInput=Date.now(),e===goal.x)&&a===goal.y&&(finish=!0,win.classList.add('showing'))}),renderMaze()}genMaze(),anim(),window.addEventListener('keydown',function(a){keys.map(function(e){-1<e.l.indexOf(a.keyCode)&&(e.pressed=!0)})}),window.addEventListener('keyup',function(a){keys.map(function(e){-1<e.l.indexOf(a.keyCode)&&(e.pressed=!1)})}),beginButton.addEventListener('click',function(){win.classList.remove('showing'),player.x=player.y=1,genMaze()}); </script> </body></html>";
      string memory body = string.concat(Strings.toString(m.width), 
                                         ",h=", Strings.toString(m.height),
                                         ",passHint=", m.passHint ? "true" : "false", 
                                         ",hintColor='", m.hintColor,
                                         "',wallColor='", m.wallColor
                                        );
      body = string.concat(body,
                          "',cellColor='", m.cellColor,
                          "',startColor='", m.startColor,
                          "',endColor='", m.endColor,
                          "',lightOut=", m.lightOut ? "true" : "false",
                          ",fogColor='", m.fogColor,
                          "',fogSize=", Strings.toString(m.fogSize)
                          );
      return string(abi.encodePacked("data:text/html;base64,", Base64.encode(bytes(string.concat(head, body, tail)))));
  }

  function text(string memory _text, string memory x, string memory y) internal pure returns (string memory){
      return string.concat(' <text x="', x, '%" y="', y, '%" class="normal">', _text, '</text> ');
  }

  function image(Maze memory m) public pure returns (string memory){
      string memory svg;
      svg = string.concat(
          '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"> <style>.normal { fill: #FFFFFF; font-family: helvetica; font-size: 18px; dominant-baseline: bottom; text-anchor: text;} </style> <rect width="100%" height="100%" fill="#000000" />',
          text(string.concat("Width: ", Strings.toString(m.width)), "0", "10"),
          text(string.concat("Height: ", Strings.toString(m.height)), "0", "20"),
          text(string.concat("Hint Color: ", m.hintColor), "0", "30"),
          text(string.concat("Wall Color: ", m.wallColor), "0", "40"),
          text(string.concat("Cell Color: ", m.cellColor), "0", "50")
      );
      svg = string.concat(
          svg,
          text(string.concat("Start Color: ", m.startColor), "0", "60"),
          text(string.concat("End Color: ", m.endColor), "0", "70"),
          text(string.concat("Fog Color: ", m.fogColor), "0", "80"),
          text(string.concat("Fog Size: ", Strings.toString(m.fogSize)), "0", "90"),
          '</svg>'

      );
      return string(abi.encodePacked("data:image/svg+xml;base64,", Base64.encode(bytes(svg))));
  }

  function tokenURI(uint256 tokenId) public view override returns (string memory){
      string memory _name = string(abi.encodePacked("Maze #", Strings.toString(tokenId)));
      string memory _description = "A fully on chain maze game. It is also your pass to our next 3D maze collection. Use WSAD to control the player for a better playing experience.";
      Maze memory m = genMaze(tokenId);
      return string(
          abi.encodePacked(
              "data:application/json;base64,",
              Base64.encode(
                  bytes(
                      abi.encodePacked(
                          '{"name":"', _name,
                          '", "description": "', _description,
                          '", "attributes": [', property(m), 
                          '], "image":"', image(m), 
                          '", "animation_url":"', animatedURI(m), '"}'
                      )
                  )
              )
          )
      );
  }

  function withdraw() external onlyOwner {
      (bool success, ) = msg.sender.call{value: address(this).balance}("");
      require(success, "Transfer failed.");
  }

  function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
      super.setApprovalForAll(operator, approved);
  }
  
  function approve(address operator, uint256 tokenId) public override payable onlyAllowedOperatorApproval(operator) {
      super.approve(operator, tokenId);

  }

  function transferFrom(address from, address to, uint256 tokenId) public override payable onlyAllowedOperator(from){
      super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId) public override payable onlyAllowedOperator(from) {
      super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override payable onlyAllowedOperator(from){
      super.safeTransferFrom(from, to, tokenId, data);
  }
}