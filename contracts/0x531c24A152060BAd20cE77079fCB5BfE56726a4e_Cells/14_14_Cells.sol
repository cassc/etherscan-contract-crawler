// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);
        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)
            for {
                let i := 0
            } lt(i, len) {
            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)
                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)
                mstore(resultPtr, out)
                resultPtr := add(resultPtr, 4)
            }
            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
            mstore(result, encodedLen)
        }
        return string(result);
    }
}

contract Cells is ERC721, Ownable, ERC2981 {
    using Strings for uint256;

    // =================================
	// Storage
	// =================================

    uint256 public constant maxSupply = 3131;
    uint256 public price = 0.005 ether;
    uint256 public numMinted;  

    mapping(address => uint8) public minted;

    bool public saleIsActive;

    // =================================
	// Metadata
	// =================================

    function generateHTMLandSVG(address _address) internal pure returns (string memory finalHtml, string memory finalSvg) {
        (string memory color1, string memory color2, string memory color3) = getColors(_address);

        string memory HTMLfirstBlock = '<canvas id="golCanvas"></canvas><style>* {margin:0;}body { background: rgb(37,38,30);height: 100%;}</style> <script>var canvas = document.getElementById("golCanvas");canvas.width = window.innerWidth;canvas.height = window.innerHeight;var WIDTH = canvas.width;var HEIGHT = canvas.height;var ctx = canvas.getContext("2d");var LEN = 10;var x = Math.floor(WIDTH/LEN);var y = HEIGHT/LEN;var myGol;var golTmp;function initTmp(){for(var xVal = 0; xVal<=x+2;xVal++){golTmp[xVal] = new Array();for(var yVal = 0; yVal<=y+2; yVal++){golTmp[xVal][yVal] = 0;}}}function initMatrix(){myGol = new Array();golTmp = new Array();for(var xVal = 0; xVal<=x+2;xVal++){myGol[xVal] = new Array();golTmp[xVal] = new Array();for(var yVal = 0; yVal<=y+2; yVal++){golTmp[xVal][yVal] = 0;var randVal = Math.floor((Math.random()*2));myGol[xVal][yVal] = randVal;if (randVal == 1){draw(xVal+1,yVal+1);}}}}function draw(x,y){ctx.fillRect(LEN*(x-1),LEN*(y-1),LEN,LEN);}function nextStep(){initTmp();ctx.fillStyle = "#';
        string memory HTMLsecondBlock = '";ctx.fillRect(0,0,WIDTH,HEIGHT);for(var xVal = 1; xVal<=x+1;xVal++){for(var yVal = 1; yVal<=y+1; yVal++){var neighbourSum = myGol[xVal-1][yVal] + myGol[xVal-1][yVal-1] + myGol[xVal-1][yVal+1] + myGol[xVal][yVal-1] + myGol[xVal][yVal+1] + myGol[xVal+1][yVal] + myGol[xVal+1][yVal+1] + myGol[xVal+1][yVal-1];if(myGol[xVal][yVal] == 1){if(neighbourSum == 2 || neighbourSum == 3){golTmp[xVal][yVal] = 1;ctx.fillStyle = "#';
        string memory HTMLthirdBlock = '";draw(xVal,yVal);}} else {if(neighbourSum == 3) {golTmp[xVal][yVal] = 1;ctx.fillStyle = "#';
        string memory HTMLfourthBlock = '";draw(xVal,yVal);}}}}myGol = golTmp.slice();}initMatrix();setInterval(nextStep, 80);</script>';

        string memory SVGfirstBlock = '<svg xmlns="http://www.w3.org/2000/svg" width="350" height="350"><rect width="350" height="350" style="fill:rgb(37,38,30)" /><rect x="80" y="110" width="40" height="40" style="fill:#';
        string memory SVGsecondBlock = '" /><rect x="200" y="90" width="40" height="40" style="fill:#';
        string memory SVGthirdBlock = '" /><rect x="170" y="210" width="40" height="40" style="fill:#';

        return(
            string(abi.encodePacked(HTMLfirstBlock, color1, HTMLsecondBlock, color2, HTMLthirdBlock, color3, HTMLfourthBlock)),
            string(abi.encodePacked(SVGfirstBlock, color1, SVGsecondBlock, color2, SVGthirdBlock, color3, '" /></svg>'))
        );
    }

    function getColors(address _address) internal pure returns (string memory color1, string memory color2, string memory color3){
        string memory addr = toString(abi.encodePacked(_address));

        color1 = getSlice(3, 8, addr);
        color2 = getSlice(9, 14, addr);
        color3 = getSlice(15, 20, addr);
        
    }

    function toString(bytes memory data) internal pure returns(string memory) {
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(2 + data.length * 2);
        str[0] = "0";
        str[1] = "x";
        for (uint i = 0; i < data.length; i++) {
            str[2+i*2] = alphabet[uint(uint8(data[i] >> 4))];
            str[3+i*2] = alphabet[uint(uint8(data[i] & 0x0f))];
        }
        return string(str);
    }

    function getSlice(uint256 begin, uint256 end, string memory text) internal pure returns (string memory) {
        bytes memory a = new bytes(end-begin+1);
        for(uint i=0;i<=end-begin;i++){
            a[i] = bytes(text)[i+begin-1];
        }
        return string(a);    
    }

    function htmlToImageURI(string memory html) internal pure returns (string memory) {
        string memory baseURL = "data:text/html;base64,";
        string memory htmlBase64Encoded = Base64.encode(bytes(string(abi.encodePacked(html))));
        return string(abi.encodePacked(baseURL,htmlBase64Encoded));
    }

    function svgToImageURI(string memory svg) internal pure returns (string memory) {
        string memory baseURL = "data:image/svg+xml;base64,";
        string memory svgBase64Encoded = Base64.encode(bytes(string(abi.encodePacked(svg))));
        return string(abi.encodePacked(baseURL,svgBase64Encoded));
    }

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        (string memory html, string memory svg) = generateHTMLandSVG(ownerOf(tokenId));

        string memory imageURIhtml = htmlToImageURI(html);
        string memory imageURIsvg = svgToImageURI(svg);

        return string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"',
                                "Cell | ", uint2str(tokenId),"",
                                '", "description":"", "attributes":"", "image":"', imageURIsvg,'", "animation_url":"', imageURIhtml,'"}'
                            )
                        )
                    )
                )
            );
    }

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    // =================================
	// Mint
	// =================================

    function mint(uint8 quantity) public payable {
        require(saleIsActive, "sale is not active");
        require(numMinted + quantity <= maxSupply, "invalid claim");
        require(quantity > 0, "invalid quantity");
        require(minted[msg.sender] + quantity <= 5, "invalid quantity per address");
        require(msg.value >= price * quantity, "invalid price");

        for (uint8 i = 0; i < quantity; i++) {
            numMinted += 1;
            _safeMint(_msgSender(), numMinted);
        }

        minted[msg.sender] += quantity;
    }

    // =================================
	// Owner functions
	// =================================

    function setPrice(uint256 _price) public onlyOwner {
        price = _price;
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function setSaleStatus(bool state) public onlyOwner {
        saleIsActive = state;
    }

    // =================================
	// Overrides
	// =================================

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // =================================
	// Constructor
	// =================================
    
    constructor() ERC721("Cells", "CEL") {
        _setDefaultRoyalty(msg.sender, 300);
        for (uint8 i = 1; i <= 50; i++) {
            _safeMint(_msgSender(), i);
        }
        numMinted += 50;
    }
}