// SPDX-License-Identifier:Unlicensed
pragma solidity >= 0.8.16;

import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";




contract Renderer is Ownable {
    string public dataURL;
    uint[] private tokenMetadata;
    address public entropyContractAddress = 0x01cc1bD2dece86e54481f1e6aEffC2FCC6915480;
    
    struct Attribute {
        bool darkMode;
        bool intent;
        bool data;
        bool creation;
    }

    constructor(
        string memory dataURL_,
        uint[] memory tokenMetadata_
    ){
        dataURL = dataURL_;
        tokenMetadata = tokenMetadata_;
    }

    function render(string memory blockNumber, bytes32 blockHash , string memory wsProvider) public view returns (string memory renderedContract) {
        // initialize all variables and their defaults
        bytes memory html; 
        string memory creationString = '{"trait_type":"Creation","value":"Minted"}';
        string memory darkModeString = '{"trait_type":"Mode","value":"Light"}';
        string memory contentString;

        // function to get tokenId (because I was too stupid to add it to the inputs :D)
        uint tokenId = getTokenId(stringToUint(blockNumber));

        // get the data for this token
        Attribute memory token = getData(tokenId);


        // create the strings to be appended to the tokenURI Json
        if(token.creation == true){creationString = '{"trait_type":"Creation","value":"Curated"}';}

        if(token.intent == true && token.data == true) { contentString = '{"trait_type":"Content","value":"Data & Intent"}'; }
        else if(token.data == true) { contentString = '{"trait_type":"Content","value":"Data"}'; }
        else { contentString = '{"trait_type":"Content","value":"Intent"}'; }

        if(token.darkMode == true){darkModeString = '{"trait_type":"Mode","value":"Dark"}';}

        // do the work !
        html = abi.encodePacked('<!doctype html><html><head><meta name=viewport content="width=device-width,initial-scale=1"><title>Absolute Zero</title><style>body,html{width:100vw;height:100vh;margin:0;padding:0;background-color:#000}body{filter:brightness(1.3) contrast(1.1)}.lightMode{filter:invert(1) contrast(1.08)!important}canvas{width:50%;height:50%;filter:drop-shadow(0px 0px 6px black) invert(1);top:0;padding:0}#canvas2{transform-origin:center center;transform:scaleX(-1)}#canvas3{transform-origin:center center;transform:scaleY(-1)}#canvas4{transform-origin:center center;transform:scale(-1)}#wrapper{background-color:#000;width:80vw;height:80vh;position:absolute;top:0;bottom:0;left:0;right:0;margin:auto;border:solid .2px rgba(255,255,255,.4);box-shadow:inset 0 0 150px rgb(225 215 255 / 22%);display:flex;flex-wrap:wrap}#title{color:rgb(255,255,255,.3);font-family:sans-serif;font-size:.7em;margin:auto;left:0;right:0;opacity:0;text-align:center;bottom:7vh;position:absolute;transition:opacity .4s ease-in}.infader{animation:fadeIn 10s}.outfader{animation:fadeOut 20s}.visible{opacity:1!important}#bg{width:100%;height:100%}</style></head><body class=lightMode><div id=wrapper onmouseenter=toggleTitle() onmouseleave=toggleTitle()><canvas id=canvas></canvas><canvas id=canvas2></canvas><canvas id=canvas3></canvas><canvas id=canvas4></canvas></div><div id=title>Loading...</div><script>const scaleFactor=3e3,length=1,spaceBetweenLines=6,lineWidth=5,lineHeight=5,block={number:',blockNumber,',hash:"', Strings.toHexString(uint256(blockHash), 32) ,'"};var lightSeed,raritySeed,r,vals,random,p,drawData=!1,drawIntent=!1,lightMode=!0,points=[],x=0,y=0;const canvas=document.getElementById("canvas"),context=canvas.getContext("2d"),canvas2=document.getElementById("canvas2"),context2=canvas2.getContext("2d"),canvas3=document.getElementById("canvas3"),context3=canvas3.getContext("2d"),canvas4=document.getElementById("canvas4"),context4=canvas4.getContext("2d");var height=canvas.height=canvas2.height=canvas3.height=canvas4.height=.8*window.innerHeight*2,width=canvas.width=canvas2.width=canvas3.width=canvas4.width=.8*window.innerWidth*2;async function start(){await init(),await initVariables(),calculatePoints()}function calculatePoints(){p=points[0];let t=height,e=0;for(;t>0&&!(e>height);){for(var a=0;a<points.length;a++){var n=getValue((p=points[a]).x,p.y,a);if(drawData){let e=n/10;context.fillStyle="rgba(0,0,0,"+e+")",context.fillRect(6*a,t,6,6)}p.vx+=1*Math.sin(n),p.vy+=1*Math.cos(n),p.vx*=.95,p.vy*=.9,p.x+=p.vx,p.y-=p.vy,drawIntent&&(context.fillStyle="rgba(0,0,0,.02)",context.fillRect(p.x,p.y,5,5)),t=p.y}e+=1}canvas2.getContext("2d").drawImage(canvas,0,0),canvas3.getContext("2d").drawImage(canvas,0,0),canvas4.getContext("2d").drawImage(canvas,0,0)}function initVariables(){random=PCGR(),vals=[rnd(1,10,1),rnd(1,10,1),rnd(1,10,1),rnd(1,10,1),rnd(1,3,1)/3e3],raritySeed=rnd(0,19,0),lightSeed=rnd(0,19,0),6!=raritySeed&&9!=raritySeed||(drawData=!0,drawIntent=!0),raritySeed%2==0?drawIntent=!0:drawData=!0,3==lightSeed&&(lightMode=!1,document.body.classList.remove("lightMode"))}function init(){for(points=[],x=0;x<width;x+=6)points.push({x:x,y:height,vx:0,vy:0});document.getElementById("title").innerHTML="Block "+block.number}function displayValues(){console.log("a: "+vals[0],"b: "+vals[1],"n: "+vals[2],"m: "+vals[3],"scale: "+vals[4]),console.log("Rarities:Light Seed : "+lightSeed+"Light Mode : "+lightMode+"Rarity Seed : "+raritySeed+"Data : "+drawData+"Intent : "+drawIntent)}function getValue(t,e){return t=(t-width/2)*vals[4],e=(e-height/2)*vals[4],vals[0]*Math.sin(vals[2]*Math.PI*t)*Math.sin(vals[3]*Math.PI*e)+vals[1]*Math.sin(vals[3]*Math.PI*t)*Math.sin(vals[2]*Math.PI*e)}function rnd(t,e,a){const n=(random.next()*(e-t)+t).toFixed(a);return parseFloat(n)}function PCGR(t=getStateFromHash(block.hash)){const e=Math.pow(2,-32),a=32557,n=19605;let i=new Uint16Array(4);return s(t),{seed:s,next(){const t=i[0],s=i[1],o=i[2],c=i[3],d=33103+a*t|0,r=63335+a*s+(n*t+(d>>>16))|0,h=31614+a*o+n*s+(62509*t+(r>>>16))|0,l=5125+a*c+(n*o+62509*s)+(22609*t+(h>>>16));i[0]=d,i[1]=r,i[2]=h,i[3]=l;const g=(c<<21)+((c>>2^o)<<5)+((o>>2^s)>>11);return e*((g>>>(c>>11)|g<<(31&-(c>>11)))>>>0)}};function s(t){t||(t=getStateFromHash());for(let e=0;e<i.length;e++)i[e]=t[e]}}function getStateFromHash(t){const e=Math.floor((t.length-2)/2),a=[];for(let n=0;n<e;n++){const e=2+2*n;a.push(parseInt(t.slice(e,e+2),16))}const n=hash32(a,42069),i=hash32(a,69420),s=new Uint16Array(4),o=new DataView(s.buffer);return o.setUint32(0,n),o.setUint32(4,i),s}function hash32(t,e=0){for(var a,n=65535,i=255,s=1540483477,o=t.length,c=e^o,d=0;o>=4;)a=((a=t[d]&i|(t[++d]&i)<<8|(t[++d]&i)<<16|(t[++d]&i)<<24)&n)*s+(((a>>>16)*s&n)<<16),c=(c&n)*s+(((c>>>16)*s&n)<<16)^(a=((a^=a>>>24)&n)*s+(((a>>>16)*s&n)<<16)),o-=4,++d;switch(o){case 3:c^=(t[d+2]&i)<<16;case 2:c^=(t[d+1]&i)<<8;case 1:c=((c^=t[d]&i)&n)*s+(((c>>>16)*s&n)<<16)}return c=((c^=c>>>13)&n)*s+(((c>>>16)*s&n)<<16),(c^=c>>>15)>>>0}function toggleLightMode(){document.body.classList.toggle("lightMode")}function toggleTitle(){document.getElementById("title").classList.toggle("visible")}0!=block.number?start():(document.body.innerHTML="",document.body.style.backgroundColor="#0C0C0C",document.body.classList=""),window.addEventListener("resize",(function(t){console.warn("Window resizing detected, adapting..."),height=canvas.height=canvas2.height=canvas3.height=canvas4.height=.8*window.innerHeight*2,width=canvas.width=canvas2.width=canvas3.width=canvas4.width=.8*window.innerWidth*2,start()}))</script></body></html>');
        return string(abi.encodePacked('data:application/json;utf8,{"description":"Visual representation of the blockchain increasing entropy.","name":"Absolute Zero Block #', blockNumber ,'","attributes":[{"trait_type":"State","value":"Absolute Zero"},',contentString,',',darkModeString,',',creationString,'],"image":"',dataURL,blockNumber,'.png","animation_url":"data:text/html;base64,',Base64.encode(html),'"}'));
    }

    function getData(uint tokenId) internal view returns (Attribute memory){
        // get the metadata for the tokenId requested by parsing the big tokenMetada bit string
        uint metadataForRange = tokenMetadata[tokenId/64];
        uint tokenPosition = tokenId%64;
        uint tokenData = metadataForRange >>  (252 - tokenPosition * 4);
        
        bool darkModeValue = (tokenData & 8) != 0;
        bool intentValue  = (tokenData & 4) != 0;
        bool dataValue = (tokenData & 2) != 0;
        bool creationValue = (tokenData & 1) != 0;

        return Attribute({ darkMode : darkModeValue , intent: intentValue, data: dataValue, creation: creationValue});

    }


    function getTokenId(uint blockNumber) internal view returns (uint){
        uint possibleBlock;

        // first look into tokens 1-11 since they are curated and thus not sorted (linear search)
        for(uint i=1;i<12;i++){
            possibleBlock = ICaller(entropyContractAddress).blockDB(i).blockNumber;
            if(blockNumber == possibleBlock){ return i; }
        }

        // if not we perform a binary search inside the rest
        uint totalSize = 512;
        uint low = 12;
        uint high = 512;
        uint mid;

        while(low != high){
            mid = (low + high) /2;

            possibleBlock = ICaller(entropyContractAddress).blockDB(mid).blockNumber;

            if(blockNumber ==  possibleBlock){ return mid; }
            else if(blockNumber > possibleBlock){ low = mid++; }
            else{ high= mid--; }
        }

        return low;
    }

    function setNewdataURL(string memory newURL) public onlyOwner {
        dataURL = newURL;
    }

    function updateMetadata(uint[] memory newMetadata) public onlyOwner{
        tokenMetadata = newMetadata;
    }

    function stringToUint(string memory _str) pure internal returns (uint) {
        uint res;
        for (uint256 i = 0; i < bytes(_str).length; i++) {
            if ((uint8(bytes(_str)[i]) - 48) < 0 || (uint8(bytes(_str)[i]) - 48) > 9) {
                return 0;
            }
            res += (uint8(bytes(_str)[i]) - 48) * 10**(bytes(_str).length - i - 1);
        }
        
        return res;
    }
}

interface ICaller {
    struct Block {
        uint blockNumber;
        bytes32 blockHash;
    }

    function blockDB(uint) external view returns (Block memory);
}