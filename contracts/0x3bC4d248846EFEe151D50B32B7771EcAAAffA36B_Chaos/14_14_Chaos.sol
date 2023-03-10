// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

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

contract Chaos is ERC721, Ownable, ERC2981 {
    using Strings for uint256;

    // =================================
	// Storage
	// =================================

    bool public burnIsActive;
    uint256 public numMinted; 

    address immutable public cells;

    // =================================
	// Metadata
	// =================================

    string constant internal sprott_linz_a = '({ x, y, z }, dt) { x += y * dt; y += (-x + y * z) * dt; z += (1 - y * y) * dt; return { x, y, z }; }';
    string constant internal halvorsen = '({ x, y, z }, dt) { const a = 1.4; x += (-a * x - 4 * y - 4 * z - y * y) * dt; y += (-a * y - 4 * z - 4 * x - z * z) * dt; z += (-a * z - 4 * x - 4 * y - x * x) * dt; return { x, y, z }; }';
    string constant internal aizawa = '({ x, y, z }, dt) { const a = 0.95; const b = 0.7; const c = 0.6; const d = 3.5; const e = 0.25; const f = 0.1; x += ((z - b) * x - d * y) * dt; y += (d * x + (z - b) * y) * dt; z += (c + a * z - (z * z * z) / 3 - (x * x + y * y) * (1 + e * z) + f * z * (x * x * x)) * dt; return { x, y, z }; }';

    function generateHTMLandSVG(address _address, uint256 funcNum) internal pure returns (string memory finalHtml, string memory finalSvg) {
        (string memory color1, string memory color2, string memory color3) = getColors(_address);

        string memory HTMLfirstBlock = '<!DOCTYPE html> <html lang="en"> <head> <meta charset="UTF-8" /> <meta http-equiv="X-UA-Compatible" content="IE=edge" /> <meta name="viewport" content="width=device-width, initial-scale=1.0" /> <title>Chaos</title> </head> <body> <canvas class="canvas" id="golCanvas"></canvas> <style> .canvas { width: 600px; height: 400px; position: absolute; top: 60%; left: 50%; transform: translate(-50%, -50%); } </style> <script> function lines';
        string memory HTMLsecondBlock = 'const canvas = document.getElementById("golCanvas"); canvas.width = window.innerWidth; canvas.height = window.innerHeight; const ctx = canvas.getContext("2d"); const dt = 0.01; var rotation_speed = 0.01; var steps_per_frame = 5; var duration_till_replace_path = 100000; const FPS = 150; const scale_factor = Math.min(canvas.width, canvas.height) / 2 - 10; var q = 0; var a = canvas.width / 7; var b = canvas.width / 6; var c = canvas.width / 2; let paths = []; let colors = ["#';
        string memory HTMLthirdBlock = '"]; let chosenAttractorFunction = lines; var number_of_paths = 3; updatePaths(); function updatePaths() { paths = []; let epsilon_base = Math.random() - Math.random(); for (var i = 0; i < number_of_paths; i++) { let epsilon = epsilon_base + (Math.random() - 0.01) * 0.001; let withing_point_epsilon = (Math.random() - 0.01) * 0.001; paths.push([ { x: epsilon + withing_point_epsilon, y: epsilon + withing_point_epsilon, z: epsilon + withing_point_epsilon, }, ]); } } function extendPath(path, steps) { for (var i = 0; i < steps; i++) { const lastP = path[path.length - 1]; const p = chosenAttractorFunction(lastP, dt); path.push(p); } return path; } function scale(points, size) { const mx = Math.min(...points.slice(1).map(({ x, y, z }) => x)); const Mx = Math.max(...points.slice(1).map(({ x, y, z }) => x)); const my = Math.min(...points.slice(1).map(({ x, y, z }) => y)); const My = Math.max(...points.slice(1).map(({ x, y, z }) => y)); const mz = Math.min(...points.slice(1).map(({ x, y, z }) => z)); const Mz = Math.max(...points.slice(1).map(({ x, y, z }) => z)); const s = (v, mv, Mv) => (size * (v - mv)) / (Mv - mv); return points.slice(1).map(({ x, y, z }) => { x = s(x, mx, Mx); y = s(y, my, My); z = s(z, mz, Mz); return { x, y, z }; }); } function draw(path, i) { if (q > 2 * Math.PI) q = 0; const map = ({ x, y, z }) => [ (x - a) * Math.cos(q) - (y - b) * Math.sin(q) + c, z, ]; ctx.beginPath(); ctx.strokeStyle = colors[i]; path .slice(1) .map(map) .forEach((p) => ctx.lineTo(p[0], p[1])); ctx.stroke(); } function update() { ctx.clearRect(0, 0, canvas.width, canvas.height); q -= rotation_speed; for (var i = 0; i < paths.length; i++) { paths[i] = extendPath(paths[i], steps_per_frame); draw(scale(paths[i], scale_factor), i); while (paths[i].length > duration_till_replace_path) paths[i].shift(); } } function main() { resize(); setInterval(update, 1000 / FPS); } function resize() { canvas.width = window.innerWidth; canvas.height = window.innerHeight; a = canvas.width / 7; b = canvas.width / 6; c = canvas.width / 2; } window.addEventListener("resize", resize, false); main(); </script> </body> </html>';

        string memory SVGfirstBlock = '<svg xmlns="http://www.w3.org/2000/svg" width="350" height="350"> <rect width="350" height="350" style="fill:rgb(37,38,30)" /> <defs> <linearGradient id="grad" x1="0%" y1="0%" x2="100%" y2="0%"> <stop offset="0%" style="stop-color:#';
        string memory SVGsecondBlock = ';stop-opacity:1" /> <stop offset="50%" style="stop-color:#';
        string memory SVGthirdBlock = ';stop-opacity:1" /> <stop offset="100%" style="stop-color:#';
        string memory SVGfourthBlock = ';stop-opacity:1" /> </linearGradient> </defs> <path d="M50 300 C 40 220, 75 10, 150 150 S 270 200, 300 50" style="fill:none;stroke:url(#grad);stroke-width:10"/> </svg>';

        if (funcNum == 0) {
            return(
                string(abi.encodePacked(HTMLfirstBlock, sprott_linz_a, HTMLsecondBlock, color1, '", "#', color2, '", "#', color3, HTMLthirdBlock)),
                string(abi.encodePacked(SVGfirstBlock, color1, SVGsecondBlock, color2, SVGthirdBlock, color3, SVGfourthBlock))
            );
        } else if (funcNum == 1) {
            return(
                string(abi.encodePacked(HTMLfirstBlock, halvorsen, HTMLsecondBlock, color1, '", "#', color2, '", "#', color3, HTMLthirdBlock)),
                string(abi.encodePacked(SVGfirstBlock, color1, SVGsecondBlock, color2, SVGthirdBlock, color3, SVGfourthBlock))
            );
        } else {
            return(
                string(abi.encodePacked(HTMLfirstBlock, aizawa, HTMLsecondBlock, color1, '", "#', color2, '", "#', color3, HTMLthirdBlock)),
                string(abi.encodePacked(SVGfirstBlock, color1, SVGsecondBlock, color2, SVGthirdBlock, color3, SVGfourthBlock))
            );
        }
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
        (string memory html, string memory svg) = generateHTMLandSVG(ownerOf(tokenId), (tokenId % 3));

        string memory imageURIhtml = htmlToImageURI(html);
        string memory imageURIsvg = svgToImageURI(svg);

        return string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"',
                                "Chaos | ", uint2str(tokenId),"",
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

    function burnCells(uint256 firstId, uint256 secondId, uint256 thirdId) public {
        require(burnIsActive, "Burn is not active");

        IERC721(cells).safeTransferFrom(msg.sender, address(0x000000000000000000000000000000000000dEaD), firstId);
        IERC721(cells).safeTransferFrom(msg.sender, address(0x000000000000000000000000000000000000dEaD), secondId);
        IERC721(cells).safeTransferFrom(msg.sender, address(0x000000000000000000000000000000000000dEaD), thirdId);

        numMinted += 1;
        _safeMint(msg.sender, numMinted);
    }

    // =================================
	// Owner functions
	// =================================

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function setBurnStatus(bool state) public onlyOwner {
        burnIsActive = state;
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
    
    constructor(address _cells) ERC721("Chaos", "CHA") {
        cells = _cells;

        _setDefaultRoyalty(msg.sender, 300);

        numMinted += 1;
        _safeMint(msg.sender, numMinted);
    }
}