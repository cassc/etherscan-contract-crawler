// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";


contract Rectangles is ERC721Enumerable, Ownable {

    using Counters for Counters.Counter;
    uint256 private maxSupply = 64;
    mapping(uint256 => address) public creators;
    mapping(uint256 => TokenData) tokens;
    bool private paused;
    event MintEvent(address indexed sender);
 
    struct TokenData {
        uint8 x;
        uint8 y;
        uint8 w;
        uint8 h;
        uint8 color;
        uint8 blink;
        uint time;
    }

    Counters.Counter private _tokenIds;

    constructor() ERC721("64 Rectangles", "RECTS") {
        paused = false;
    }

    function str8(uint8 v) internal pure returns (string memory) {
        return Strings.toString(v);
    }

    modifier whenNotPaused() {
        require(!paused, "paused");
        _;
    }

    modifier onlyCreator(uint256 _id) {
        require(
            creators[_id] == msg.sender || owner() == msg.sender,
            "onlyCreator"
        );
        _;
    }

    function _unpause() public onlyOwner {
        paused = false;
    }

    function _pause() public onlyOwner {
        paused = true;
    }

    function setTokenData(
        uint256 id,
        uint8 x,
        uint8 y,
        uint8 w,
        uint8 h,
        uint8 color,
        uint8 blink
    ) public onlyCreator(id) {

        require(w>0 && h>0, "sizeError");

        tokens[id].x = x;
        tokens[id].y = y;
        tokens[id].w = w;
        tokens[id].h = h;
        tokens[id].color = color;
        tokens[id].blink = blink;
        tokens[id].time = block.timestamp;
        
    }

    function getTokens(uint256 sIdx, uint256 len) public view returns (TokenData[] memory){
        //uint256 length = totalSupply();
        TokenData[] memory _tokens = new TokenData[](len);
        for (uint256 i = 0; i <len; ++i) {
            _tokens[i] = tokens[sIdx+i];
        }
        return _tokens;
    }

    function getCreators(uint256 sIdx, uint256 len) public view returns (address[] memory){
        address[] memory _creators = new address[](len);
        for (uint256 i = 0; i <len; ++i) {
            _creators[i] = creators[sIdx+i];
        }
        return _creators;
    }

    function _mintToken(address _to) internal returns (uint256 _tokenId) {
        uint256 tokenId = _tokenIds.current();
        _safeMint(_to, tokenId);
        _tokenIds.increment();
        return tokenId;
    }

    function mint(
        uint8 x,
        uint8 y,
        uint8 w,
        uint8 h,
        uint8 c,
        uint8 b
    ) public payable whenNotPaused {
        require(
            totalSupply() < maxSupply,
            "errorSupply"
        );
        //price = 0.005 + 0.06 * (w*h)/10000;
        uint256 price = (5000+6*uint256(w)*uint256(h)) * 0.000001 ether;
        require(
            msg.value >= price,
            "errorEth"
        );
        uint256 tokenId = _mintToken(msg.sender);
        creators[tokenId] = msg.sender;
        setTokenData(tokenId, x, y, w, h, c, b);
        emit MintEvent(msg.sender);
    }

    function _mint(
        uint8 x,
        uint8 y,
        uint8 w,
        uint8 h,
        uint8 c,
        uint8 b
    ) public onlyOwner {
        uint256 tokenId = _mintToken(msg.sender);
        creators[tokenId] = msg.sender;
        setTokenData(tokenId, x, y, w, h, c, b);
    }

    function html() private view returns (bytes memory) {
        return
            abi.encodePacked(
                "<!DOCTYPE html>"
                "<html>"
                "<head>"
                "<title>64 Rectangles</title>"
                '<style>'
                "body { background:#bbb;overflow:hidden;font-size:30px;font-family:sans-serif; } "
                "#con{position:absolute;left:0;top:0;transform-origin: 0 0;} "
                ".rect{ color:#fff; display:flex; align-items:center; justify-content:center; overflow:hidden; position: absolute;animation: ani 1s infinite alternate ease-in-out;} "
                "@keyframes ani{from {opacity: 0;} to {opacity: 1;}} "
                "</style>"
                "<script>",
                    json(),
                    js(),
                "</script>"
                "</head>"
                "<body>"
                "<div id='con'></div>"
                "</body>"
                "</html>"
            );
    }
    
    function js() private pure returns (bytes memory) {
        return
            abi.encodePacked(
                'var w=window,dt=document;'
                'w.onload=()=>{'
                'var dc=dt.createElement.bind(dt),'
                'cols=["#000","#f00","#0f0","#00f","#ff0","#f0f","#0ff","#fff"],'
                'con=dt.getElementById("con");'
                'for(let i=0;i<jsons.length;i++){'
                    'let d=jsons[i];'
                    "let d1=dc('div'),"
                        "d2=dc('div');"
                    "let d1s=d1.style,"
                        "d2s=d2.style;"
                        'd1.classList.add("rect");'
                        'd1.innerText=""+(i+1);'
                        'd1s.left=d2s.left=(d[0]*10)+"px";'
                        'd1s.top=d2s.top=(d[1]*10)+"px";'
                        'd1s.width=d2s.width=(d[2]*10)+"px";'
                        'd1s.height=d2s.height=(d[3]*10)+"px";'
                        'd1s.animationDuration=(d[5])+"0ms";'
                        'd1s.backgroundColor=cols[Math.floor(d[4]/10)];'
                        'd1s.zIndex=""+(i*2);'

                        'd2s.position="absolute";'
                        'd2s.zIndex=""+(i*2-1);'
                        'd2s.backgroundColor=cols[d[4]%10];'
                        
                        'con.appendChild(d1);'
                        'con.appendChild(d2);'
                '}'

                'rz();'
                'w.addEventListener("resize",rz);'
                'function rz(e){'
                    'con.style.transform=`scale(${w.innerWidth/1000},${w.innerHeight/1000})`;'
                '}'

                '}'
            );
    }

    function json() private view returns (bytes memory) {
        bytes memory str = "var jsons=[";
        uint256 supply = totalSupply();
        for (uint256 i = 0; i < supply; ++i) {            
            str = abi.encodePacked(
                    str,
                    "[",
                    str8(tokens[i].x), ",",
                    str8(tokens[i].y), ",",
                    str8(tokens[i].w), ",",
                    str8(tokens[i].h), ",",
                    str8(tokens[i].color), ",",
                    str8(tokens[i].blink),
                    "],"
                );
        }
        return abi.encodePacked(str,"];");
    }

    function image(uint256 _id) private view returns (bytes memory) {

        string memory x = str8(tokens[_id].x);
        string memory y = str8(tokens[_id].y);
        string memory w = str8(tokens[_id].w);
        string memory h = str8(tokens[_id].h);
        string memory blink = str8(tokens[_id].blink);
        uint8 col = tokens[_id].color;
        uint8 colIdx = col%10;
        uint8 colIdx2 = (col/10);

        return abi.encodePacked(

            '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"' 
            ' style="background-color:#bbb;">'
                '<style>'
                    '@keyframes ani {0%{ opacity: 0;} 100%{ opacity: 1;}}'
                '</style>'
                '<rect width="',w,'"'
                    ' height="',h,'"'
                    ' x="',x,'"'
                    ' y="',y,'"'
                    ' style="fill:',getHex(colIdx),';" />' 
                '<rect width="',w,'"'
                    ' height="',h,'"'
                    ' x="',x,'"'
                    ' y="',y,'"'
                    ' style="fill:',getHex(colIdx2),';animation: ani ',blink,'0ms infinite linear alternate;" />'
            '</svg>'
        );
    }

    function getHex(uint8 colIdx) public pure returns (bytes memory) {
        bytes memory colHex = new bytes(0);
        if(colIdx==1) colHex = bytes("#f00");
        else if(colIdx==2) colHex = bytes("#0f0");
        else if(colIdx==3) colHex = bytes("#00f");
        else if(colIdx==4) colHex = bytes("#ff0");
        else if(colIdx==5) colHex = bytes("#f0f");
        else if(colIdx==6) colHex = bytes("#0ff");
        else if(colIdx==7) colHex = bytes("#fff");
        else colHex = bytes("#000");
        return colHex;
    }

    function tokenURI(uint256 _id) public view override returns (string memory) {
        require(
            _exists(_id),
            "idError"
        );
        bytes memory metadata = abi.encodePacked(
            "{"
            '"name":"Rectangle #',Strings.toString(_id+1),'",'
            '"description":"A generative art made by multiple minters",',
            '"image":"data:image/svg+xml;base64,',Base64.encode(image(_id)),'",'
            '"external_url": "https://kitasenjudesign.com/rects/",', 
            '"animation_url":"data:text/html;base64,',
            Base64.encode(html()),'",'
            '"attributes": ['
                '{'
                    '"trait_type": "no",'
                    '"value": ',Strings.toString(_id+1),
                '}'                
            ']'
            "}"
        );

        return string(abi.encodePacked("data:application/json,", metadata));
    }

    function withdrawAll() external onlyOwner {
        uint256 amount = address(this).balance;
        require(payable(owner()).send(amount));
    }

}