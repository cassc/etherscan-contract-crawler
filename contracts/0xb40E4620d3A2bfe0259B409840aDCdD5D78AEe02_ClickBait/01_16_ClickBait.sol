// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;
pragma abicoder v2;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

import "base64-sol/base64.sol";
import "erc721a/contracts/ERC721A.sol";

import "./sstore2/SSTORE2.sol";
import "./utils/DynamicBuffer.sol";
import "hardhat/console.sol";

interface PunkDataInterface {
    function punkImage(uint16 index) external view returns (bytes memory);
}

interface CLICKS {
    function colorToRarityScore(string memory color) external view returns (uint16);
}

contract ClickBait is Ownable, ERC721A, ERC2981 {
    using Address for address;
    using DynamicBuffer for bytes;
    using Strings for *;
    
    uint public constant lovelyPrimeNumber = 107839786668602559178668060348078522694548577690162289924414440996859;
    
    uint public constant internalMintBatchSize = 30;
    uint public constant costPerToken = 0.01 ether;
    bool public isMintActive;
    
    uint public constant maxSupply = 10_000;
    uint96 public constant sellerFeeBasisPoints = 500;
    
    string public constant contractExternalLink = "https://www.capsule21.com/collections/clickbait";
    string public constant tokenExternalLink = contractExternalLink;
    
    address private contractDescriptionPointer;
    
    uint constant colorsInEachToken = 4;
    
    PunkDataInterface public constant punkDataContract = PunkDataInterface(0x16F5A35647D6F03D5D3da7b35409D65ba03aF3B2);
    
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    
    address public constant originalCLICKS = 0x57B7304A79918d47Ac0122BeDBeb874A804b6990;
    
    function flipMintState() external onlyOwner {
        isMintActive = !isMintActive;
    }
    
    constructor() ERC721A("ClickBait", "CB") {
        _setDefaultRoyalty(address(this), sellerFeeBasisPoints);
    }
    
    function setContractDescription(string calldata _contractDescription) external onlyOwner {
        contractDescriptionPointer = SSTORE2.write(bytes(_contractDescription));
    }
    
    address public constant orderedColors = 0x82eB97f77615fF2C8bAC2989e8DA9E39Cf9d91d3;
    address public constant colorsToPunks = 0x1909D49B585d9A55a792636FD81CacD61F787A9E;
    address public constant oneOfOnes = 0x8FbB1af81d6Ecd8B2ACB0fB47F2077001f79e501;
    address public constant oneOfOneTitles = 0x11B00eDC96Deb626BbC02D0A8353c0B4D4Db2696;
    
    uint public constant totalColors = 219;
    uint public constant maxPunkPerColor = 55;
    uint public constant oneOfOnesCount = 59;
    uint public constant maxTitleLength = 23;
    
    function mint(uint quantity) public payable {
        require(isMintActive);
        require(totalMintCost(quantity, msg.sender) == msg.value, "Incorrect amount of ether sent");
        
        _mintBatch(msg.sender, quantity);
    }
    
    function airdrop(address to, uint quantity) public payable {
        require(isMintActive);
        require(totalMintCost(quantity, msg.sender) == msg.value, "Incorrect amount of ether sent");
        
        _mintBatch(to, quantity);
    }
    
    function stringCompare(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }
    
    function punkSvg(uint tokenId, string memory colorName) public view returns (string memory) {
        bytes memory pixels = punkDataContract.punkImage(uint16(tokenId));
        
        bytes memory svgBytes = DynamicBuffer.allocate(1024 * 128);
        
        svgBytes.appendSafe(abi.encodePacked('<svg class="small" width="1200" height="1200" shape-rendering="crispEdges" xmlns="http://www.w3.org/2000/svg" version="1.2" viewBox="0 0 24 24"><style>rect.x1{fill: #638596d8} rect:not(.b){width:1px;height:1px}</style><rect x="0" y="0" style="width:100%;height:100%" fill="#638596" />'));
        
        bytes memory buffer = new bytes(8);
        for (uint256 y = 0; y < 24; y++) {
            for (uint256 x = 0; x < 24; x++) {
                uint256 p = (y * 24 + x) * 4;
                if (uint8(pixels[p + 3]) > 0) {
                    for (uint256 i = 0; i < 4; i++) {
                        uint8 value = uint8(pixels[p + i]);
                        
                        buffer[i * 2 + 1] = _HEX_SYMBOLS[value & 0xf];
                        value >>= 4;
                        buffer[i * 2] = _HEX_SYMBOLS[value & 0xf];
                    }
                    
                    bytes memory rectStart = abi.encodePacked(
                        '<rect x="',
                        x.toString(),
                        '" y="',
                        y.toString()
                    );
                    
                    svgBytes.appendSafe(
                        abi.encodePacked(
                            rectStart,
                            '" fill="#',
                            string(buffer),
                            '"/>'
                        )
                    );
                    
                    if (!stringCompare(string.concat(colorName, "ff"), string(buffer))) {
                        svgBytes.appendSafe(
                            abi.encodePacked(
                                rectStart,
                                '" class="x1',
                                '"/>'
                            )
                        );
                    }
                }
            }
        }
        
        svgBytes.appendSafe('</svg>');
        return string(svgBytes);
    }
    
    function _extraData(
        address from,
        address to,
        uint24 previousExtraData
    ) internal view virtual override returns (uint24) {
        return from == address(0) ? entropyForExtraData() : previousExtraData;
    }
    
    function getTokenSeed(uint256 _tokenId) internal view returns (uint) {
        return uint(keccak256(abi.encode(_ownershipOf(_tokenId).extraData, _tokenId)));
    }
    
    function toHexStringNoPrefix(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length);
        for (uint256 i = buffer.length; i > 0; i--) {
            buffer[i - 1] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        return string(buffer);
    }
    
    bytes32 constant enderHash = keccak256(abi.encodePacked(bytes("|")));
    
    function getOneOfOneTitleAtIndex(uint index) internal view returns (string memory) {
        require(index < oneOfOnesCount);
        bytes memory allTitles = SSTORE2.read(oneOfOneTitles);
        bytes memory outputBytes = DynamicBuffer.allocate(maxTitleLength * 2);
        
        for (uint i = (maxTitleLength * index); i < (maxTitleLength * (index + 1)); ++i) {
            bytes32 currentCharHash = keccak256(abi.encodePacked(allTitles[i]));
            
            if (currentCharHash == enderHash) {
                break;
            }
            
            outputBytes.appendSafe(abi.encodePacked(allTitles[i]));
        }
        
        return string(outputBytes);
    }
    
    function getColorAtIndex(uint index) internal view returns (string memory) {
        bytes memory colorArray = SSTORE2.read(orderedColors);
        return toHexStringNoPrefix(uintByteArrayValueAtIndex(colorArray, index), 3);
    }
    
    function getPunksOfColorByColorIndex(uint index) internal view returns (uint16[] memory) {
        bytes memory phunksArray = SSTORE2.read(colorsToPunks);
        
        uint startingPoint = index * maxPunkPerColor;
        uint endingPoint = startingPoint + maxPunkPerColor;
        
        uint idxInReturnAry;
        
        uint16[] memory tmpAry = new uint16[](maxPunkPerColor);
        
        for (uint i = startingPoint; i < endingPoint; i++) {
            uint8 firstByte = uint8(phunksArray[i * 2]);
            uint8 secondByte = uint8(phunksArray[i * 2 + 1]);
            
            uint16 id = uint16(firstByte) << 8 | uint16(secondByte);
            
            if (id < 10_000) {
                tmpAry[idxInReturnAry] = id;
                idxInReturnAry++;
            }
        }
        
        uint16[] memory returnAry = new uint16[](idxInReturnAry);
        
        for(uint i = 0; i < idxInReturnAry; i++) {
            returnAry[i] = tmpAry[i];
        }
        
        return returnAry;
    }
    
    function getOneOfOneColorIndexes(uint index) internal view returns (uint8[colorsInEachToken] memory ret) {
        bytes memory oneOfOneArray = SSTORE2.read(oneOfOnes);
        
        uint startingPoint = index * colorsInEachToken;
        uint endingPoint = startingPoint + colorsInEachToken;
        
        uint retIdx;
        
        for (uint i = startingPoint; i < endingPoint; i++) {
            ret[retIdx] = uint8(oneOfOneArray[i]);
            retIdx++;
        }
    }
    
    function uintByteArrayValueAtIndex(bytes memory fakeArray, uint index) private pure returns (uint) {
        uint big = uint24(uint8(fakeArray[index * 3]) * 2 ** 16);
        uint med = uint24(uint8(fakeArray[index * 3 + 1]) * 2 ** 8);
        uint small = uint8(fakeArray[index * 3 + 2]);
        
        return big + med + small;
    }
    
    function entropyForExtraData() internal view returns (uint24) {
        uint256 randomNumber = uint256(
            keccak256(
                abi.encodePacked(
                    tx.gasprice,
                    block.number,
                    block.timestamp,
                    block.difficulty,
                    block.basefee,
                    msg.data,
                    blockhash(block.number - 1),
                    msg.sender
                )
            )
        );
        return uint24(randomNumber);
    }
    
    function tokenURI(uint256 id) public view override returns (string memory) {
        require(_exists(id), "Token does not exist");

        return constructTokenURI(id);
    }
    
    function tokenName(uint tokenId) private pure returns (bytes memory) {
        return abi.encodePacked("ClickBait #", tokenId.toString());
    }
    
    function getOneOfOneTitle(uint tokenId) private view returns (string memory) {
        return getOneOfOneTitleAtIndex(tokenIdToOneOfOneSelectionId(tokenId));
    }
    
    function duplicateColorCount(uint tokenId) internal view returns (uint) {
        (,uint8[4] memory colorIndexes,) = tokenImage(tokenId);
        uint dupeCount;
        
        for (uint i; i < 4; ++i) {
            for (uint j; j < 4; ++j) {
                if (i != j && colorIndexes[i] == colorIndexes[j]) {
                    ++dupeCount;
                }
            }
        }
        
        if (dupeCount == 0) {
            return 0;
        } else if (dupeCount == 2) {
            return 1;
        } else if (dupeCount == 6) {
            return 2;
        } else {
            return 3;
        }
    }
    
    function calculateTokenRarityScore(uint tokenId) public view returns (uint total) {
        (,,string[4] memory colors) = tokenImage(tokenId);
        for (uint i = 0; i < 4; ++i) {
            total += CLICKS(originalCLICKS).colorToRarityScore(colors[i]);
        }
    }
    
    function tokenAttributes(uint tokenId) public view returns (string memory) {
        require(_exists(tokenId), "Token does not exist");
        (,,string[4] memory colors) = tokenImage(tokenId);
        uint duplicateColors = duplicateColorCount(tokenId);
        uint cv = totalColorDifference(tokenId);
        (uint r, uint g, uint b, uint l, uint s) = colorIntensitiesInToken(tokenId);
        uint rarityScore = calculateTokenRarityScore(tokenId);
        rarityScore = rarityScore * 1000 / 40_000;
        
        bytes memory outputBytes = DynamicBuffer.allocate(256 * 64);
        outputBytes.appendSafe("[");
        
        for (uint i = 0; i < 4; i++) {
            bytes memory squareObj = abi.encodePacked('{"trait_type":"Square ', (i + 1).toString(), '", "value":"#', colors[i], '"}');
            
            outputBytes.appendSafe(squareObj);
            
            if (i < 3) {
                outputBytes.appendSafe(", ");
            }
        }
        
        if (tokenIsOneOfOne(tokenId)) {
            bytes memory oneOfOneObj = abi.encodePacked('{"trait_type":"1 of 1", "value":"', getOneOfOneTitle(tokenId), '"}');
            
            outputBytes.appendSafe(", ");
            outputBytes.appendSafe(oneOfOneObj);
        }
        
        bytes memory dupeObj = abi.encodePacked(
            '{"trait_type":"Duplicate Color Count", "display_type": "number", "max_value": 3, "value":', duplicateColors.toString(), '}'
        );
        
        outputBytes.appendSafe(", ");
        outputBytes.appendSafe(dupeObj);
        
        
        outputBytes.appendSafe(", ");
        
        outputBytes.appendSafe(abi.encodePacked(
            '{"trait_type":"Color Variation", "display_type": "number", "max_value": 1000, "value":', (cv * 1000 / (255 * 4)).toString(), '}'
        ));
        
        outputBytes.appendSafe(", ");
        
        outputBytes.appendSafe(abi.encodePacked(
            '{"trait_type":"Redness", "display_type": "number", "max_value": 1000, "value":', (r * 1000 / 3060).toString(), '}'
        ));
        
        outputBytes.appendSafe(", ");
        
        outputBytes.appendSafe(abi.encodePacked(
            '{"trait_type":"Greenness", "display_type": "number", "max_value": 1000, "value":', (g * 1000 / 3060).toString(), '}'
        ));
        
        outputBytes.appendSafe(", ");
        
        outputBytes.appendSafe(abi.encodePacked(
            '{"trait_type":"Blueness", "display_type": "number", "max_value": 1000, "value":', (b * 1000 / 3060).toString(), '}'
        ));
        
        outputBytes.appendSafe(", ");
        
        outputBytes.appendSafe(abi.encodePacked(
            '{"trait_type":"Luminance", "display_type": "number", "max_value": 1000, "value":', (l * 1000 / (255 * 4)).toString(), '}'
        ));
        
        outputBytes.appendSafe(", ");
        
        outputBytes.appendSafe(abi.encodePacked(
            '{"trait_type":"Saturation", "display_type": "number", "max_value": 1000, "value":', (s / 4).toString(), '}'
        ));
        
        outputBytes.appendSafe(", ");
        
        outputBytes.appendSafe(abi.encodePacked(
            '{"trait_type":"Rarity Score", "display_type": "number", "max_value": 1000, "value":', rarityScore.toString(), '}'
        ));
        
        outputBytes.appendSafe("]");
        
        return string(outputBytes);
    }
    
    function constructTokenURI(uint tokenId) private view returns (string memory) {
        (string memory svg,,) = tokenImage(tokenId);
        string memory html = tokenHTMLPage(tokenId);
        
        string memory b64Svg = Base64.encode(bytes(svg));
        string memory b64Html = Base64.encode(bytes(html));
        
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{',
                                '"name":"', tokenName(tokenId), '",'
                                '"description":', SSTORE2.read(contractDescriptionPointer), ','
                                '"image_data":"data:image/svg+xml;base64,', b64Svg, '",'
                                '"animation_url":"data:text/html;charset=utf-8;base64,', b64Html, '",'
                                '"external_url":"', tokenExternalLink, '",'
                                '"attributes": ', tokenAttributes(tokenId),
                                '}'
                            )
                        )
                    )
                )
            );
    }
    
    function colorDifferenceBetweenTwo24BitRGBColors(uint24 color1, uint24 color2) private pure returns (uint) {
        uint24 red1 = uint8(color1 >> 16);
        uint24 green1 = uint8(color1 >> 8);
        uint24 blue1 = uint8(color1);
        
        uint24 red2 = uint8(color2 >> 16);
        uint24 green2 = uint8(color2 >> 8);
        uint24 blue2 = uint8(color2);
        
        uint redDiff = absoluteDiff(red1, red2);
        uint greenDiff = absoluteDiff(green1, green2);
        uint blueDiff = absoluteDiff(blue1, blue2);
        
        uint squareOfDiff = ((redDiff ** 2) * 30 / 100) +
                            ((greenDiff ** 2) * 59 / 100) +
                            ((blueDiff ** 2) * 11 / 100);
        
        return squareOfDiff;
    }
    
    function totalColorDifference(uint tokenId) internal view returns (uint totalDiff) {
        bytes memory colorArray = SSTORE2.read(orderedColors);
        (,uint8[4] memory colorIndexes,) = tokenImage(tokenId);
        for (uint i; i < 4; ++i) {
            for (uint j = i + 1; j < 4; ++j) {
                if (i != j) {
                    uint24 c1 = uint24(uintByteArrayValueAtIndex(colorArray, colorIndexes[i]));
                    uint24 c2 = uint24(uintByteArrayValueAtIndex(colorArray, colorIndexes[j]));
                    totalDiff += sqrt(colorDifferenceBetweenTwo24BitRGBColors(c1, c2));
                }
            }
        }
    }
    
    function computeColorSaturationFrom24BitUint(uint24 color) private pure returns (uint) {
        uint red = uint8(color >> 16);
        uint green = uint8(color >> 8);
        uint blue = uint8(color);
        
        uint maxRGB = max(red, max(green, blue));
        uint minRGB = min(red, min(green, blue));
        
        if (maxRGB == 0) {
            return 0;
        }
        
        return (maxRGB - minRGB) * 1000 / maxRGB;
    }
    
    function max(uint a, uint b) private pure returns (uint) {
        return a > b ? a : b;
    }
    
    function min(uint a, uint b) private pure returns (uint) {
        return a < b ? a : b;
    }
    
    function computeColorLuminanceFrom24BitUint(uint24 color) internal pure returns (uint24) {
        uint24 b = uint8(color);
        uint24 g = uint8(color >> 8);
        uint24 r = uint8(color >> 16);
        
        return (r * 299 + g * 587 + b * 114) / 1000;
    }
    
    function colorIntensitiesIn24BitColor(uint24 color) private pure returns (uint, uint, uint) {
        int red = int(uint(uint8(color >> 16)));
        int green = int(uint(uint8(color >> 8)));
        int blue = int(uint(uint8(color)));
        
        return (
            uint(red - (green + blue) + 510),
            uint(green - (red + blue) + 510),
            uint(blue - (red + green) + 510)
        );
    }
    
    function colorIntensitiesInToken(uint tokenId) internal view returns (uint r, uint g, uint b, uint l, uint s) {
        bytes memory colorArray = SSTORE2.read(orderedColors);
        (,uint8[4] memory colorIndexes,) = tokenImage(tokenId);
        
        for (uint i; i < 4; ++i) {
            uint24 c1 = uint24(uintByteArrayValueAtIndex(colorArray, colorIndexes[i]));
            (uint rDiff, uint gDiff, uint bDiff) = colorIntensitiesIn24BitColor(c1);
            r += rDiff;
            g += gDiff;
            b += bDiff;
            l += computeColorLuminanceFrom24BitUint(c1);
            s += computeColorSaturationFrom24BitUint(c1);
        }
    }
    
    function absoluteDiff(uint a, uint b) private pure returns (uint) {
        return a > b ? a - b : b - a;
    }
    
    function tokenIdToOneOfOneSelectionId(uint tokenId) internal view returns (uint) {
        uint offsetIndex;
        
        if (_exists(1)) {
            offsetIndex = _ownershipOf(1).extraData + 10_000;
        }
        
        return ((tokenId + offsetIndex) * lovelyPrimeNumber) % maxSupply;
    }
    
    function tokenIsOneOfOne(uint tokenId) internal view returns (bool) {
        return tokenIdToOneOfOneSelectionId(tokenId) < oneOfOnesCount;
    }
    
    function tokenImage(uint tokenId) public view returns (
        string memory svg,
        uint8[4] memory colorIndexes,
        string[4] memory colors
    ) {
        require(_exists(tokenId), "Token does not exist");
        uint seed = getTokenSeed(tokenId);
        
        if (tokenIsOneOfOne(tokenId)) {
            colorIndexes = getOneOfOneColorIndexes(tokenIdToOneOfOneSelectionId(tokenId));
        } else {
            for (uint i = 0; i < colorsInEachToken; i++) {
                 colorIndexes[i] = uint8(seed % totalColors);
                 seed = seed / totalColors;
            }
        }
        
        for (uint i = 0; i < colorsInEachToken; ++i) {
            colors[i] = getColorAtIndex(colorIndexes[i]);
        }
        
        bytes memory svgBytes = DynamicBuffer.allocate(1024 * 128);
        
        svgBytes.appendSafe(bytes('<svg class="big visible" width="1200" height="1200" shape-rendering="crispEdges" viewBox="0 0 24 24" version="1.1" xmlns="http://www.w3.org/2000/svg">'));
        
        svgBytes.appendSafe(abi.encodePacked(
            '<rect class="b" width="24" height="24" x="0" y="0" fill="#', colors[0], '" />'
        ));
        
        svgBytes.appendSafe(abi.encodePacked(
            '<rect class="b" width="20" height="20" x="2" y="3" fill="#', colors[1], '" />'
        ));
        
        svgBytes.appendSafe(abi.encodePacked(
            '<rect class="b" width="16" height="16" x="4" y="6" fill="#', colors[2], '" />'
        ));
        
        svgBytes.appendSafe(abi.encodePacked(
            '<rect class="b" width="12" height="12" x="6" y="9" fill="#', colors[3], '" />'
        ));
        
        svgBytes.appendSafe(bytes('</svg>'));
        
        svg = string(svgBytes);
    }
    
    function tokenHTMLPage(uint tokenId) public view returns (string memory) {
        require(_exists(tokenId), "Token does not exist");
        bytes memory HTMLBytes = DynamicBuffer.allocate(1024 * 128);
        uint seed = getTokenSeed(tokenId);
        
        (string memory image, uint8[4] memory colorIndexes,) = tokenImage(tokenId);
        
        HTMLBytes.appendSafe('<!DOCTYPE html>');
        HTMLBytes.appendSafe(abi.encodePacked('<body><style>body{display:flex;align-items:center; justify-content:center;position:relative;} rect{cursor:pointer} *{box-sizing:border-box;margin:0;padding:0;border:0; user-select: none;} svg{width: 100%;height: 100%;max-width: 100%; max-height: 100%;position:fixed;top:0;left:0;transition: 0.4s all; opacity: 0; pointer-events: none;} svg.visible{opacity: 1; pointer-events: unset;}</style>'));
        
        for (uint i = 0; i < 4; ++i) {
            uint16[] memory colorPunks = getPunksOfColorByColorIndex(colorIndexes[i]);
            
            uint randomPunk = colorIndexes[i] == 0 ? seed % maxSupply : colorPunks[seed % colorPunks.length];
            
            seed = seed / maxSupply;
            
            HTMLBytes.appendSafe(bytes(punkSvg(randomPunk, getColorAtIndex(colorIndexes[i]))));
        }
        
        HTMLBytes.appendSafe(bytes(image));

        HTMLBytes.appendSafe('<script>function init(){var c,b=document.querySelectorAll(".small"),a=document.querySelector(".big"),d=!1;let e=a=>new Promise(b=>setTimeout(()=>{b()},a));a.addEventListener("touchstart",async a=>{a.touches.length>1&&(event.stopPropagation(),await f(),g())});var f=async function(){for([idx,el]of(d=!0,b[0].classList.add("visible"),a.classList.remove("visible"),document.querySelectorAll(".small").entries()))0!=idx&&el.classList.toggle("visible"),await e(400);for([idx,el]of Array.from(b).reverse().entries())3!=idx&&(el.classList.toggle("visible"),await e(400));d=!1},g=function(){clearTimeout(c),d||(a.classList.add("visible"),b.forEach(a=>a.classList.remove("visible")))};a.addEventListener("click",async d=>{if(d.shiftKey){await f(),g();return}var e=d.target,h=b[[...e.parentElement.children].indexOf(e)];h&&(a.classList.remove("visible"),h.classList.add("visible"),c=setTimeout(g,4e3))}),b.forEach(a=>a.addEventListener("click",g))}init()</script></body></html>');
        
        return string(HTMLBytes);
    }
    
    function totalMintCost(uint numTokens, address minter) public pure returns (uint) {
        return numTokens * costPerToken;
    }
    
    function sqrt(uint256 x) public pure returns (uint256 result) {
        if (x == 0) {
            return 0;
        }

        // Set the initial guess to the least power of two that is greater than or equal to sqrt(x).
        uint256 xAux = uint256(x);
        result = 1;
        if (xAux >= 0x100000000000000000000000000000000) {
            xAux >>= 128;
            result <<= 64;
        }
        if (xAux >= 0x10000000000000000) {
            xAux >>= 64;
            result <<= 32;
        }
        if (xAux >= 0x100000000) {
            xAux >>= 32;
            result <<= 16;
        }
        if (xAux >= 0x10000) {
            xAux >>= 16;
            result <<= 8;
        }
        if (xAux >= 0x100) {
            xAux >>= 8;
            result <<= 4;
        }
        if (xAux >= 0x10) {
            xAux >>= 4;
            result <<= 2;
        }
        if (xAux >= 0x4) {
            result <<= 1;
        }

        // The operations can never overflow because the result is max 2^127 when it enters this block.
        unchecked {
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1; // Seven iterations should be enough
            uint256 roundedDownResult = x / result;
            return result >= roundedDownResult ? roundedDownResult : result;
        }
    }
    
    function _mintBatch(address to, uint quantity) internal {
        require(msg.sender == tx.origin, "No contracts");
        require(totalSupply() + quantity <= maxSupply, "Mint exceeds supply");
        
        uint batchCount = quantity / internalMintBatchSize;
        uint remainder = quantity % internalMintBatchSize;

        for (uint256 i = 0; i < batchCount; i++) {
            _mint(to, internalMintBatchSize);
        }

        if (remainder > 0) {
            _mint(to, remainder);
        }
    }
    
    function contractURI() public view returns (string memory) {
        string memory svg = punkSvg(1903, "e4eb17");
        string memory b64Svg = Base64.encode(bytes(svg));
        
        return
            string(
                abi.encodePacked(
                    'data:application/json;base64,',
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{',
                                '"name":"', name(), '",'
                                '"seller_fee_basis_points":', sellerFeeBasisPoints.toString(), ','
                                '"fee_recipient":"', address(this).toHexString(), '",'
                                '"description":', SSTORE2.read(contractDescriptionPointer), ','
                                '"image":"data:image/svg+xml;base64,', b64Svg, '",'
                                '"external_link":"', tokenExternalLink, '"'
                                '}'
                            )
                        )
                    )
                )
            );
    }
    
    address constant pivAddress = 0xf98537696e2Cf486F8F32604B2Ca2CDa120DBBa8;
    address constant middleAddress = 0xC2172a6315c1D7f6855768F843c420EbB36eDa97;
    
    function withdraw() external {
        require(msg.sender == tx.origin, "No contracts");
        require(address(this).balance > 0, "Nothing to withdraw");
        
        uint total = address(this).balance;
        uint half = total / 2;
        
        Address.sendValue(payable(middleAddress), half);
        Address.sendValue(payable(pivAddress), total - half);
    }
    
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981) returns (bool) {
        return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }
    
    receive() external payable {}
    fallback (bytes calldata _inputText) external payable returns (bytes memory _output) {}
}