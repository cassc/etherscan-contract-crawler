// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;
import "erc721a/contracts/ERC721A.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
contract OnChainMaze3D is DefaultOperatorFilterer, ERC721A, ReentrancyGuard, Ownable{
  uint256 public MAX_PUBLIC_MINT=1024-256;
  uint256 public MAX_COLLECTION_SIZE=1024;
  uint256 public mintPrice=0.01024 ether;
  uint256 public maxMintPerWallet=2;
  string[] passables = ["20,66,114,","60,42,33,","109,103,228,","129,12,168,","59,24,95,","40,42,58,",
  "98,79,130,","21,0,80,","86,43,8,","85,57,57,","81,85,126,"]; // 11
  string[] walls = ["10,38,71,","26,18,11,","69,60,103,","45,3,59,","0,0,92,","0,0,0,","63,59,108,","24,39,71,","71,45,45,","27,36,48,"]; // 10
  string[] hints = ["251,86,7,","255,0,110,","255,190,11,","58,134,255,","131,56,236,"]; // 5
  string[] starts = ["251,248,204,","185,251,192,","255,207,210,","152,245,225,","255,214,165,","189,178,255,","255,255,252,","202,255,191,","142,236,245,",
  "255,214,165,","255,173,173,"]; // 11
  uint256[] widths = [4, 5, 6, 7, 8, 9, 10, 11, 12]; // 9
  uint256[] gravities = [0, 1, 2]; // 3

  constructor() ERC721A("OnChainMaze3D", "OCM3D") {
  }

  function mint(uint256 quantity) external payable{
      // Mint price: 0.01024, collection size 1024, max mint 2.
      require(totalSupply() + quantity <= MAX_PUBLIC_MINT, "Reached max supply");
      require(_numberMinted(msg.sender) + quantity <= maxMintPerWallet, "Max 2 mint per wallet!");
      require(quantity * mintPrice <= msg.value, "Funds not enough.");
      /*
         This is the first on chain first person 3d game.
         The reason why we made maze on chain is the following: https://www.numberphile.com/videos/the-lightning-algorithm
         Indeed, the lightning can be simulated using the shortest path to the ground from the cloud.

         Let us introduce the next collection:
         On Chain ASCII Lightning.

         This time it will be in svg unlike the maze games, and the result will be rendered as ASCII art.
         The coolest thing we can ever think of being on chain, at least as cool as Terraforms.

         64 holders of 2d maze and 128 holders of 3d maze will be airdropped once sold out of the lightning collection.
         Holders of 3d maze will be able to mint during a whitelist phase of 24 hr.
         total supply 1024, mint price 0.0256.
      */
      _safeMint(msg.sender, quantity);
  }
  function airDrop(address[] calldata addresses) external onlyOwner{
      require(totalSupply() + addresses.length <= MAX_COLLECTION_SIZE, "Reached max supply");
      for (uint256 i=0; i<addresses.length; i++){
          _safeMint(addresses[i], 1);
      }
  }

  struct Maze {
      bool passHint;
      string passableColor;
      string wallColor;
      string hintColor;
      string startColor;
      uint256 width;
      uint256 gravity;
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
      m.passableColor = passables[randomRange(tokenId, "passableColor", 0, 11)];
      m.wallColor = walls[randomRange(tokenId, "wallColor", 0, 10)];
      m.passHint = (randomRange(tokenId, "passHint?", 0, 2) == 1);
      m.hintColor = hints[randomRange(tokenId, "hintColor", 0, 5)];
      m.startColor = starts[randomRange(tokenId, "startColor", 0, 11)];
      m.width = widths[randomRange(tokenId, "width", 0, 9)];
      m.gravity = gravities[randomRange(tokenId, "gravity", 0, 3)];
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
      _property = string(abi.encodePacked(
          _property,
          '{"trait_type":"Wall Color","value":"', m.wallColor, '"},',
          '{"trait_type":"Passable Color","value":"', m.passableColor, '"},'
      )
                        );
      _property = string(abi.encodePacked(
          _property,
          '{"trait_type":"Start Color","value":"', m.startColor, '"},',
          '{"display_type":"number","trait_type":"Width","value":', Strings.toString(m.width), '},',
          '{"display_type":"number","trait_type":"Gravity","value":', Strings.toString(m.gravity), '}'
          )
                        );
      return _property;
  }
  function animatedURI(Maze memory m) public pure returns (string memory){
      string memory head = '<!DOCTYPE html><html lang="en" ><head> <meta charset="UTF-8"> <title>3D Maze</title><style>body {background: #000;display: -webkit-box;display: -ms-flexbox;display: flex;-webkit-box-orient: vertical;-webkit-box-direction: normal;-ms-flex-direction: column;flex-direction: column;height: 100vh;width: 100%;}canvas { position: absolute; top: 0%; left: 0%; width: 100vmin; height: 100vmin;display: -webkit-box;display: -ms-flexbox;display: flex;}#win {position: absolute;top: 0%;left: 0%;background-color: rgba(0,0,0,.8);text-align: center;width: 100vmin;height: 100vmin;color: #eee;opacity: 0;display: none;transition: opacity .5s;}#win.showing {display: inline-block;opacity: 1;}#win, button {font: 20px Helvetica;}button {padding: 8px;}</style></head><body><head><meta charset="UTF-8"><title>3D maze</title></head><body> <canvas id="c"></canvas> <div id=win class=showing> <p><button id=beginButton>Start</button></p> </div></body><script> var size = ';
      string memory tail = ';</script><script>var speed=5,sens=.05,width=500,axeY=100,tanTheta=5.6572,tanTheta2=tanTheta**2,finish=!1,CANVAS_HEIGHT=CANVAS_WIDTH="800",polygon=[];const wallVertex=[[[0,0,0],[0,0,1],[0,1,1],[0,1,0]],[[0,0,0],[1,0,0],[1,0,1],[0,0,1]],[[0,0,0],[1,0,0],[1,1,0],[0,1,0]]],wallCenter=[[0,.5,.5],[.5,0,.5],[.5,.5,0]];for(var maze=[],allWalls=[],x=0;x<size;++x)for(var y=0;y<size;++y){for(var z=0;z<size;++z)allWalls.push([x,y,z,0]),allWalls.push([x,y,z,1]),allWalls.push([x,y,z,2]);allWalls.push([size,x,y,0]),allWalls.push([x,size,y,1]),allWalls.push([x,y,size,2])}var old,player,keysDown,right,seen=new Set,walls=[],cuts=new Set,starts=new Set,ends=new Set,passed=new Set,pq=(starts.add([0,0,0,0].toString()),starts.add([0,0,0,1].toString()),starts.add([0,0,0,2].toString()),starts.add([1,0,0,0].toString()),starts.add([0,1,0,1].toString()),starts.add([0,0,1,2].toString()),ends.add([size-1,size-1,size-1,0].toString()),ends.add([size-1,size-1,size-1,1].toString()),ends.add([size-1,size-1,size-1,2].toString()),ends.add([size,size-1,size-1,0].toString()),ends.add([size-1,size,size-1,1].toString()),ends.add([size-1,size-1,size,2].toString()),[]),requestAnimFrame=window.requestAnimationFrame||window.webkitRequestAnimationFrame||window.mozRequestAnimationFrame||function(e){window.setTimeout(e,1e3/fps)};function genMaze(){maze.length=0,seen=new Set,walls.length=0,cuts=new Set,passed=new Set,finish=!1;for(var e=0;e<size;++e){maze.push([]);for(var l=0;l<size;++l){maze[e].push([]);for(var a=0;a<size;++a)maze[e][l].push(!1)}}function t(e,l,a){function t(e,l,a,t){seen.has([e,l,a,t].toString())||(walls.push([e,l,a,t]),seen.add([e,l,a,t].toString()))}maze[e][l][a]||(maze[e][l][a]=!0,t(e,l,a,0),t(e,l,a,1),t(e,l,a,2),t(e+1,l,a,0),t(e,l+1,a,1),t(e,l,a+1,2))}for(t(0,0,0);0<walls.length;)wall=walls[Math.random()*walls.length|0],walls.splice(walls.indexOf(wall),1),0!=wall[wall[3]]&&wall[0]!=size&&wall[1]!=size&&wall[2]!=size&&(--(cell2=[wall[0],wall[1],wall[2]])[wall[3]],maze[wall[0]][wall[1]][wall[2]]!=maze[cell2[0]][cell2[1]][cell2[2]])&&(cuts.add(wall.toString()),t(wall[0],wall[1],wall[2]),t(cell2[0],cell2[1],cell2[2]))}function clearScreen(){ctx.fillStyle="white",ctx.fillRect(0,0,CANVAS_WIDTH,CANVAS_WIDTH)}var render=function(){clearScreen(),movePlayer(),drawWalls(),drawCompass(),drawWords("Use WSAD (player), arrow keys (camera), spacebar (jump) and shift (accelerate) to control",0,20)};function crossProduct(e,l){return[e[1]*l[2]-e[2]*l[1],e[2]*l[0]-e[0]*l[2],e[0]*l[1]-e[1]*l[0]]}function dotProduct(e,l){return e[0]*l[0]+e[1]*l[1]+e[2]*l[2]}function normalized(e){var l=Math.sqrt(e[0]**2+e[1]**2+e[2]**2);return[e[0]/l,e[1]/l,e[2]/l]}var getLeftBottom=function(e){return[Math.floor(e[0]/width),Math.floor(e[1]/width),Math.floor(e[2]/width)]},aidDealCollision=function(e,l){cuts.has(e.toString())?passed.add(e.toString()):player.l[e[3]]=l[e[3]]},dealCollision=function(e){[x_,y_,z_]=getLeftBottom(player.l),[x__,y__,z__]=getLeftBottom(e),x_-x__==-1&&aidDealCollision([x__,y__,z__,0],e),y_-y__==-1&&aidDealCollision([x__,y__,z__,1],e),z_-z__==-1&&aidDealCollision([x__,y__,z__,2],e),x_-x__==1&&aidDealCollision([x__+1,y__,z__,0],e),y_-y__==1&&aidDealCollision([x__,y__+1,z__,1],e),z_-z__==1&&aidDealCollision([x__,y__,z__+1,2],e),e=player.l.slice(0),[x_,y_,z_]=getLeftBottom(player.l),x_==size-1&&y_==size-1&&z_==size-1&&(finish=!0)},movePlayer=function(){right=normalized(crossProduct(player.dir,player.head)),old=player.l.slice(0),speed=16 in keysDown?10:5,87 in keysDown&&(player.l[0]+=player.dir[0]*speed,player.l[1]+=player.dir[1]*speed,player.l[2]+=player.dir[2]*speed,dealCollision(old)),83 in keysDown&&(player.l[0]-=player.dir[0]*speed,player.l[1]-=player.dir[1]*speed,player.l[2]-=player.dir[2]*speed,dealCollision(old)),68 in keysDown&&(player.l[0]+=right[0]*speed,player.l[1]+=right[1]*speed,player.l[2]+=right[2]*speed,dealCollision(old)),65 in keysDown&&(player.l[0]-=right[0]*speed,player.l[1]-=right[1]*speed,player.l[2]-=right[2]*speed,dealCollision(old)),32 in keysDown&&(player.l[0]+=player.head[0]*speed,player.l[1]+=player.head[1]*speed,player.l[2]+=player.head[2]*speed,dealCollision(old)),player.l[2]-=gravity,dealCollision(old),39 in keysDown&&(player.dir[0]+=right[0]*sens,player.dir[1]+=right[1]*sens,player.dir[2]+=right[2]*sens),37 in keysDown&&(player.dir[0]-=right[0]*sens,player.dir[1]-=right[1]*sens,player.dir[2]-=right[2]*sens),38 in keysDown&&(player.dir[0]+=player.head[0]*sens,player.dir[1]+=player.head[1]*sens,player.dir[2]+=player.head[2]*sens,player.head[0]-=player.dir[0]*sens,player.head[1]-=player.dir[1]*sens,player.head[2]-=player.dir[2]*sens),40 in keysDown&&(player.dir[0]-=player.head[0]*sens,player.dir[1]-=player.head[1]*sens,player.dir[2]-=player.head[2]*sens,player.head[0]+=player.dir[0]*sens,player.head[1]+=player.dir[1]*sens,player.head[2]+=player.dir[2]*sens),player.dir=normalized(player.dir),player.head=normalized(player.head)},getPoint=function(e){return[dotProduct(delta=[e[0]-player.l[0],e[1]-player.l[1],e[2]-player.l[2]],right),dotProduct(delta,player.dir),dotProduct(delta,player.head)]},solver=function(e,l){return a_=(l[0]-e[0])**2+(l[2]-e[2])**2-(l[1]-e[1])**2*tanTheta2,b_=2*((l[0]-e[0])*e[0]+(l[2]-e[2])*e[2]-(l[1]-e[1])*e[1]*tanTheta2),c_=e[0]**2+e[2]**2-e[1]**2*tanTheta2,t=(-b_+Math.sqrt(b_**2-4*a_*c_))/2/a_,t2=(-b_-Math.sqrt(b_**2-4*a_*c_))/2/a_,y1=e[1]+t*(l[1]-e[1]),y2=e[1]+t2*(l[1]-e[1]),y_=!(0<y1&&0<y2)&&0<y2?(t=t2,y2):y1,[(e[0]+t*(l[0]-e[0]))*axeY/y_,(e[2]+t*(l[2]-e[2]))*axeY/y_]},drawLine=function(e,l){theta1=Math.abs(Math.sqrt(e[0]**2+e[2]**2)/e[1]),theta2=Math.abs(Math.sqrt(l[0]**2+l[2]**2)/l[1]),0<e[1]&&theta1<=tanTheta?(polygon.push([e[0]*axeY/e[1],e[2]*axeY/e[1]]),l[1]<=0||theta2>tanTheta?polygon.push(solver(e,l)):polygon.push([l[0]*axeY/l[1],l[2]*axeY/l[1]])):0<l[1]&&theta2<=tanTheta&&(polygon.push(solver(l,e)),polygon.push([l[0]*axeY/l[1],l[2]*axeY/l[1]]))},fillPolygon=function(l){if(0!=polygon.length){let e;l=l.toString();e=cuts.has(l)?starts.has(l)||ends.has(l)?"rgba("+start+"0.1)":passed.has(l)?"rgba("+hint+"0.1)":"rgba("+pass+"0.1)":starts.has(l)||ends.has(l)?"rgba("+start+"1)":"rgba("+wallC+"1)",ctx.fillStyle=e,ctx.beginPath(),ctx.moveTo(polygon[0][0],polygon[0][1]);for(var a=1;a<polygon.length;a++)ctx.lineTo(polygon[a][0],polygon[a][1]);ctx.closePath(),ctx.strokeStyle="#000000",ctx.lineWidth=1,ctx.stroke(),ctx.fill()}},drawRect=function(e){v0=[(e[0]+wallVertex[e[3]][0][0])*width,(e[1]+wallVertex[e[3]][0][1])*width,(e[2]+wallVertex[e[3]][0][2])*width],v1=[(e[0]+wallVertex[e[3]][1][0])*width,(e[1]+wallVertex[e[3]][1][1])*width,(e[2]+wallVertex[e[3]][1][2])*width],v2=[(e[0]+wallVertex[e[3]][2][0])*width,(e[1]+wallVertex[e[3]][2][1])*width,(e[2]+wallVertex[e[3]][2][2])*width],v3=[(e[0]+wallVertex[e[3]][3][0])*width,(e[1]+wallVertex[e[3]][3][1])*width,(e[2]+wallVertex[e[3]][3][2])*width],v0=getPoint(v0),v1=getPoint(v1),v2=getPoint(v2),v3=getPoint(v3),polygon.length=0,drawLine(v0,v1),drawLine(v1,v2),drawLine(v2,v3),drawLine(v3,v0),fillPolygon(e)};function dist(e){return Math.sqrt(((e[0]+wallCenter[e[3]][0])*width-player.l[0])**2+((e[1]+wallCenter[e[3]][1])*width-player.l[1])**2+((e[2]+wallCenter[e[3]][2])*width-player.l[2])**2)}const swap=(e,l)=>[pq[e],pq[l]]=[pq[l],pq[e]];var addpq=function(a){if(!((priority=dist(a))>6*width)){pq.push([a,priority]);let e=pq.length-1,l;for(;e;){if(l=e-1>>1,priority<=pq[l][1])return;swap(e,l),e=l}}},rmpq=function(){swap(0,pq.length-1);var e=pq.pop();length=pq.length;let l=0,a=2*l+1,t;for(;a<length&&((t=2*l+2)<length&&pq[t][1]>pq[a][1]&&(a=t),!(pq[a][1]<=pq[l][1]));)swap(l,a),a=2*(l=a)+1;return e[0]},drawWalls=function(){for(ctx.setTransform(1,0,0,-1,CANVAS_WIDTH/2,CANVAS_HEIGHT/2),right=normalized(crossProduct(player.dir,player.head)),i=0;i<allWalls.length;i++)addpq(allWalls[i]);for(;0<pq.length;)elem=rmpq(),drawRect(elem);ctx.setTransform(1,0,0,1,0,0)},drawCompass=function(){[x_,y_,z_]=getLeftBottom(player.l);var e=normalized(getPoint([width*(size-.5),width*(size-.5),width*(size-.5)]));drawWords(`(${x_}, ${y_}, ${z_})`,CANVAS_WIDTH*(.5-.1*e[0]),CANVAS_HEIGHT*(.5+.1*e[2])),drawWords(`(${size-1}, ${size-1}, ${size-1})`,CANVAS_WIDTH*(.5+.1*e[0]),CANVAS_HEIGHT*(.5-.1*e[2])),ctx.beginPath(),ctx.moveTo(CANVAS_WIDTH/2+25*e[0],CANVAS_HEIGHT/2-25*e[2]),ctx.lineTo(CANVAS_WIDTH/2-25*e[0],CANVAS_HEIGHT/2+25*e[2]),ctx.lineWidth=5,ctx.stroke(),ctx.beginPath(),ctx.arc(CANVAS_WIDTH/2+30*e[0],CANVAS_HEIGHT/2-30*e[2],5,0,2*Math.PI,!0),ctx.lineWidth=5,ctx.stroke()},animationLoop=function e(){window.requestAnimFrame(e),finish&&win.classList.add("showing"),render()};function drawWords(e,l,a){ctx.font="16px Arial",ctx.fillStyle="#000000",ctx.fillText(e,l,a)}function init(){player={l:[width/2,width/2,width/2],dir:[1/1.414,1/1.414,0],head:[0,0,1]},keysDown={},walls=[],finish=!(right=[1,0,0]),genMaze()}beginButton.addEventListener("click",function(){win.classList.remove("showing"),init()}),c.width=CANVAS_WIDTH,c.height=CANVAS_HEIGHT,ctx=c.getContext("2d"),addEventListener("keydown",function(e){e.preventDefault(),keysDown[e.keyCode]=!0},!1),addEventListener("keyup",function(e){delete keysDown[e.keyCode]},!1),init(),animationLoop();</script></body></html>';
      string memory body = string.concat(Strings.toString(m.width), 
                                         ',start="', m.startColor,
                                         '",hint="', m.hintColor,
                                         '",wallC="', m.wallColor
                                        );
      body = string.concat(body,
                          '",pass="', m.passableColor,
                          '",gravity=', Strings.toString(m.gravity)
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
          text(string.concat("Gravity: ", Strings.toString(m.gravity)), "0", "20"),
          text(string.concat("Hint Color: ", m.hintColor), "0", "30"),
          text(string.concat("Wall Color: ", m.wallColor), "0", "40"),
          text(string.concat("Passable Color: ", m.passableColor), "0", "50")
      );
      svg = string.concat(
          svg,
          text(string.concat("Start Color: ", m.startColor), "0", "60"),
          '</svg>'
      );
      return string(abi.encodePacked("data:image/svg+xml;base64,", Base64.encode(bytes(svg))));
  }

  function tokenURI(uint256 tokenId) public view override returns (string memory){
      string memory _name = string(abi.encodePacked("Maze #", Strings.toString(tokenId)));
      string memory _description = "The first fully on chain 3d game. It is also your pass to our next lightning collection. Use WSAD, arrow keys and spacebar to control.";
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