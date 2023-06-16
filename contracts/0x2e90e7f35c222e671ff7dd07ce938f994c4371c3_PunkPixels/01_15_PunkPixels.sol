// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;
pragma abicoder v2;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "base64-sol/base64.sol";
import "erc721a/contracts/ERC721A.sol";

import "./sstore2/SSTORE2.sol";
import "./utils/DynamicBuffer.sol";

interface PunkDataInterface {
    function punkImage(uint16 index) external view returns (bytes memory);
    function punkAttributes(uint16 index) external view returns (string memory);
}

contract PunkPixels is Ownable, ERC721A {
    using DynamicBuffer for bytes;
    using Strings for uint256;
    
    uint public constant lovelyPrimeNumber = 8553257247280420960071286815308592234402294015157773986043468141624079;
    
    uint public constant costPerToken = 0.00025 ether;
    uint public constant maxSupply = 2_091_094;
    
    uint public constant mintBatchSize = 30;
    
    bool public isMintActive;
    
    string public externalLink = "https://punkpixels.xyz";
    
    bool public contractSealed;
    
    PunkDataInterface public immutable punkDataContract;
    
    address private punkPixelCountsPart1;
    address private punkPixelCountsPart2;
    
    mapping(string => uint8) private colorRarities;
    
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    
    modifier unsealed() {
        require(!contractSealed, "Contract sealed.");
        _;
    }
    
    function sealContract() external onlyOwner unsealed {
        contractSealed = true;
    }
    
    function flipMintState() external onlyOwner {
        isMintActive = !isMintActive;
    }
    
    constructor(address punkDataContractAddress) ERC721A("Punk Pixels", "PUNKPIX") {
        punkDataContract = PunkDataInterface(punkDataContractAddress);
    }
    
    function setPunkPixelCounts(bytes[] calldata pixelCounts) external onlyOwner unsealed {
        punkPixelCountsPart1 = SSTORE2.write(pixelCounts[0]);
        punkPixelCountsPart2 = SSTORE2.write(pixelCounts[1]);
    }
    
    function setColorRarityScores(string[] calldata colors, uint8[] calldata scores) external onlyOwner unsealed {
        for (uint i; i < colors.length; i++) {
            colorRarities[colors[i]] = scores[i];
        }
    }
    
    function getColorRarityScore(string memory color) private view returns (string memory) {
        uint8 intScore = colorRarities[color];
        
        if (intScore == 0) {
            return "Common";
        } else if (intScore == 1) {
            return "Uncommon";
        } else if (intScore == 2) {
            return "Rare";
        } else if (intScore == 3) {
            return "Epic";
        } else if (intScore == 4) {
            return "Legendary";
        } else {
            return "Priceless";
        }
    }
    
    function uintByteArrayValueAtIndex(bytes memory fakeArray, uint index) private pure returns (uint) {
        uint big = uint24(uint8(fakeArray[index * 3]) * 2 ** 16);
        uint med = uint24(uint8(fakeArray[index * 3 + 1]) * 2 ** 8);
        uint small = uint8(fakeArray[index * 3 + 2]);
        
        return big + med + small;
    }
    
    function findPunkForPixel(uint pixelId) private view returns (uint punkId, uint pixelIndexWithinPunk) {
        bytes memory allCounts = DynamicBuffer.allocate(30 * 1024);
        
        allCounts.appendSafe(SSTORE2.read(punkPixelCountsPart1));
        allCounts.appendSafe(SSTORE2.read(punkPixelCountsPart2));
        
        punkId = smallestElementInUintByteArrayLargerThanNeedle(allCounts, pixelId);
        
        uint highestPixelOfPreviousPunk = punkId == 0 ? 0 : uintByteArrayValueAtIndex(allCounts, punkId - 1);
        
        pixelIndexWithinPunk = pixelId - highestPixelOfPreviousPunk;
        
        return (punkId, pixelIndexWithinPunk);
    }
    
    function smallestElementInUintByteArrayLargerThanNeedle(bytes memory haystack, uint needle) private pure returns (uint) {
        uint left = 0;
        uint right = haystack.length / 3;
        
        while (left < right) {
            uint mid = left + (right - left) / 2;
            
            if (uintByteArrayValueAtIndex(haystack, mid) <= needle) {
                left = mid + 1;
            } else {
                right = mid;
            }
        }
        
        return left;
    }
    
    function mintPunkPixel(address toAddress, uint numTokens) public payable {
        require(isMintActive, "Mint is not active");
        require(numTokens > 0, "Mint at least one");
        require(msg.value == totalMintCost(numTokens, msg.sender), "Need exact payment");
        
        uint batchCount = numTokens / mintBatchSize;
        uint remainder = numTokens % mintBatchSize;
        
        for (uint i; i < batchCount; i++) {
            _safeMint(toAddress, mintBatchSize);
        }
        
        if (remainder > 0) {
            _safeMint(toAddress, remainder);
        }
    }
    
    function tokenIdToPixelIndex(uint tokenId) private pure returns (uint) {
        uint offsetIndex = 777737;
        
        return ((tokenId + offsetIndex) * lovelyPrimeNumber) % maxSupply;
    }
    
    function tokenURI(uint256 id) public view override returns (string memory) {
        require(_exists(id), "Token does not exist");

        return constructTokenURI(id);
    }
    
    function tokenName(uint tokenId) private pure returns (bytes memory) {
        return abi.encodePacked("Punk Pixel #", tokenId.toString());
    }
    
    function tokenDescription(uint punkId, uint xCoord, uint yCoord) private pure returns (bytes memory) {
        return abi.encodePacked(
            "The pixel at coordinates (",
            xCoord.toString(),
            ", ",
            yCoord.toString(),
            ") on CryptoPunk #",
            punkId.toString(), "."
        );
    }
    
    function constructTokenURI(uint tokenId) private view returns (string memory) {
        uint pixelIndex = tokenIdToPixelIndex(tokenId);
        
        (uint punkId, ) = findPunkForPixel(pixelIndex);
        
        (string memory svg, string memory color, uint xCoord, uint yCoord) = getPixelImageWithColor(tokenId);
        
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{',
                                '"name":"', tokenName(tokenId), '",'
                                '"description":"', tokenDescription(punkId, xCoord, yCoord), '",'
                                '"image_data":"data:image/svg+xml;base64,', Base64.encode(bytes(svg)), '",'
                                '"external_url":"', externalLink, '",'
                                    '"attributes": [',
                                        '{',
                                            '"trait_type": "color",',
                                            '"value": "#', color, '"',
                                        '},'
                                        '{',
                                            '"trait_type": "color_rarity",',
                                            '"value": "', getColorRarityScore(color), '"',
                                        '},'
                                        '{',
                                            '"trait_type": "pixel_number",',
                                            '"display_type": "number",',
                                            '"value": ', (pixelIndex + 1).toString(), ',',
                                            '"max_value": ', maxSupply.toString(), '',
                                        '},'
                                        '{',
                                            '"trait_type": "punk_id",',
                                            '"value": "', punkId.toString(), '"',
                                        '},'
                                        '{',
                                            '"trait_type": "x_coordinate",',
                                            '"value": "', xCoord.toString(), '"',
                                        '},'
                                        '{',
                                            '"trait_type": "y_coordinate",',
                                            '"value": "', yCoord.toString(), '"',
                                        '}'
                                    ']'
                                '}'
                            )
                        )
                    )
                )
            );
    }
    
    
    function getPixelColor(uint tokenId) public view returns (string memory color) {
        (, color,,) = getPixelImageWithColor(tokenId);
    }
    
    function getPixelImage(uint tokenId) public view returns (string memory svg) {
        (svg, ,,) = getPixelImageWithColor(tokenId);
    }
    
    function getPixelImageWithColor(uint tokenId) public view returns (
        string memory svg,
        string memory returnedColor,
        uint xCoord,
        uint yCoord
    ) {
        require(_exists(tokenId), "Token does not exist");
        
        uint nonBlankCount;
        
        uint thisTokenPixelIndex = tokenIdToPixelIndex(tokenId);
        (uint punkId, uint pixelIndexWithinPunk) = findPunkForPixel(thisTokenPixelIndex);
        
        bytes memory pixels = punkDataContract.punkImage(uint16(punkId));
        
        bytes memory svgBytes = DynamicBuffer.allocate(64 * 1024);
        
        svgBytes.appendSafe('<svg shape-rendering="crispEdges" xmlns="http://www.w3.org/2000/svg" version="1.2" viewBox="0 0 24 24"><style>rect{width:1px;height:1px}</style><rect x="0" y="0" style="width:100%;height:100%" fill="#638596" />');
        
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
                    
                    if (nonBlankCount == pixelIndexWithinPunk) {
                        returnedColor = string(abi.encodePacked(buffer));
                        xCoord = x + 1;
                        yCoord = y + 1;
                    }
                    
                    svgBytes.appendSafe(
                        abi.encodePacked(
                            '<rect x="',
                            x.toString(),
                            '" y="',
                            y.toString(),
                            '" fill="#',
                            string(buffer),
                            '"/>'
                        )
                    );
                    
                    if (nonBlankCount != pixelIndexWithinPunk) {
                        svgBytes.appendSafe(
                            abi.encodePacked(
                                '<rect x="',
                                x.toString(),
                                '" y="',
                                y.toString(),
                                '" fill="#638596d8',
                                '"/>'
                            )
                        );
                    }
                    
                    nonBlankCount++;
                }
            }
        }
        
        svgBytes.appendSafe('</svg>');
        
        svg = string(abi.encodePacked(
            '<svg xmlns="http://www.w3.org/2000/svg" shape-rendering="crispEdges" version="1.2" viewBox="0 0 3072 3072"><image x="0" y="0" width="100%" height="100%" image-rendering="pixelated" href="data:image/svg+xml;base64,',
            Base64.encode(svgBytes),
            '" /></svg>'
        ));
    }
    
    function withdraw() external onlyOwner {
        Address.sendValue(payable(msg.sender), address(this).balance);
    }
    
    function totalMintCost(uint numTokens, address minter) public view returns (uint) {
        if (minter == owner()) {
            return 0;
        }
        
        return numTokens * costPerToken;
    }
}