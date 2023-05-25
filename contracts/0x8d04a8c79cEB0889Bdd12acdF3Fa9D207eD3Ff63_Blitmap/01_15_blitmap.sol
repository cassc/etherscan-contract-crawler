/*
______ _     _____ _____ 
| ___ \ |   |_   _|_   _|
| |_/ / |     | |   | |  
| ___ \ |     | |   | |  
| |_/ / |_____| |_  | |  
\____/\_____/\___/  \_/                     
___  ___  ___  ______    
|  \/  | / _ \ | ___ \   
| .  . |/ /_\ \| |_/ /   
| |\/| ||  _  ||  __/    
| |  | || | | || |       
\_|  |_/\_| |_/\_|       

by dom hofmann and friends
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./blitmap-analysis.sol";
import "./string-util.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract Blitmap is ERC721Enumerable, ReentrancyGuard {
    struct SVGCursor {
        uint8 x;
        uint8 y;
        string color1;
        string color2;
        string color3;
        string color4;
    }
    
    struct VariantParents {
        uint256 tokenIdA;
        uint256 tokenIdB;
    }
    
    struct Creator {
        string name;
        bool isAllowed;
        uint256 availableBalance;
        uint8 remainingMints;
    }
    
    struct TokenMetadata {
        string name;
        address creator;
        uint8 remainingVariants;
    }
    
    struct Colors {
        uint[4] r;
        uint[4] g;
        uint[4] b;
    }
    
    address private _owner;
    mapping (address => Creator) private _allowedList;
    event AddedToAllowedList(address indexed account);
    event RemovedFromAllowedList(address indexed account);
    event Published();
    event MetadataChanged(uint256 indexed tokenId, TokenMetadata indexed newMetadata);
    
    mapping(uint256 => VariantParents) private _tokenParentIndex;
    mapping(bytes32 => bool) private _tokenPairs;
    
    bytes[] private _tokenDataIndex;
    TokenMetadata[] private _tokenMetadataIndex;
    
    string private _uriPrefix;

    bytes private constant _genesisToken = hex"0000000600ffd5719efff568000000000000000015555555555555541555555555555554140514555555555414451455555555541445045555555554144510555555555414451455555555541405145555555554155555555555555415555555555555541401114051451554145511445145155414550140514115541455114451441554145511445145155414011144514515541555555555555554155555555555555400000000000000002aaaaaaaaaaaaaa82aaaaaaaaaaaaaa800000000000000003ffffffffffffffc3ffffffffffffffc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000";
    
    uint8 private _numOriginals;
    uint8 private constant _maxNumOriginals = 128;
    uint8 private constant _maxNumVariants = 16;
    
    bool public published;
    
    modifier onlyOwner() {
        require(msg.sender == _owner);
        _;
    }
    
    modifier onlyAllowed() {
        require(isAllowed(msg.sender));
        _;
    }

    constructor() ERC721("Blitmap", "BLIT") {
        _owner = msg.sender;

        published = false;

        setBaseURI("https://api.blitmap.com/v1/metadata/");

        addAllowed(msg.sender, "dom", 128);
        addAllowed(address(0xE7bd51Dc30d4bDc9FDdD42eA7c0a283590C9D416), "jstn", 1);
        addAllowed(address(0x9BC20560301cDc15c3190f745B6D910167d4b467), "bhoka", 1);
        addAllowed(address(0xC5fFbCd8A374889c6e95f8df733e32A0e9476a9c), "BRAINDRAIND", 11);
        addAllowed(address(0x8e29B3F71a8c7276d122C88d9bf317e857ABb376), "BigPapap", 12);
        addAllowed(address(0x9Bf043a72ca1cD3DC4BCa66c9F6c1d040CfF7772), "Veenus", 12);
        addAllowed(address(0xBb01f3CAc350eD60B1bD080B7A55cC5768cFD565), "startselect", 4);
        addAllowed(address(0xf0136dEe223c9a303ae8863F9438a687C775a4a7), "pinot", 2);
        addAllowed(address(0xd1e0eb60Bda1c098353D08a167B011EA8bcd38Fa), "zod", 4);
        addAllowed(address(0x4610CC9c73C0215818fE47962eaBD93cF331856b), "KlingKlong", 4);
        addAllowed(address(0xd42bd96B117dd6BD63280620EA981BF967A7aD2B), "numo", 10);
        addAllowed(address(0xeE463034F385DD9B26efD7767406079f86edB992), "themoonladder", 4);
        addAllowed(address(0x9f2942fF27e40445d3CB2aAD90F84C3a03574F26), "askywlkr", 2);
        addAllowed(address(0x48A63097E1Ac123b1f5A8bbfFafA4afa8192FaB0), "ceresstation", 2);
        addAllowed(address(0x6EBd8991fC87F130DE28DE4b37F882d6cbE9aB28), "HighleyVarlet", 4);
        addAllowed(address(0xfB843f8c4992EfDb6b42349C35f025ca55742D33), "worm", 1);
        addAllowed(address(0x06Ac1F9f86520225b73EFCe4982c9d9505753251), "hipcityreg", 1);
        addAllowed(address(0xf4c9C5229356d39b4F852ecF6E08576EebEDB0EC), "spacedoctor", 4);
        
        mintOriginal(_genesisToken, "Genesis");
    }
    
    function _baseURI() override internal view virtual returns (string memory) {
        return _uriPrefix;
    }
    
    function setBaseURI(string memory prefix) public onlyOwner {
        _uriPrefix = prefix;
    }
    
    function addAllowed(address _address, string memory name, uint8 allowedMints) public onlyOwner {
        Creator memory creator;
        creator.name = name;
        creator.isAllowed = true;
        creator.remainingMints = allowedMints;
        _allowedList[_address] = creator;
        emit AddedToAllowedList(_address);
    }
    
    function changeMetadataOf(uint256 tokenId, TokenMetadata memory newMetadata) public onlyOwner {
        require(published == false, "b:01"); // only allow changes prior to publishing
        _tokenMetadataIndex[tokenId] = newMetadata;
        emit MetadataChanged(tokenId, newMetadata);
    }
    
    function publish() public onlyOwner {
        published = true;
        emit Published();
    }

    function removeAllowed(address _address) public onlyOwner {
        _allowedList[_address].isAllowed = false;
        emit RemovedFromAllowedList(_address);
    }

    function isAllowed(address _address) public view returns (bool) {
        return _allowedList[_address].isAllowed == true;
    }
    
    function creatorNameOf(address _address) public view returns (string memory) {
        return _allowedList[_address].name;
    }

    function mintOriginal(bytes memory tokenData, string memory name) public nonReentrant onlyAllowed {
        require(published == false, "b:01");
        require(_numOriginals < _maxNumOriginals, "b:03");
        require(tokenData.length == 268, "b:04"); // any combination of 268 bytes is technically a valid blit
        require(bytes(name).length > 0 && bytes(name).length < 11, "b:05");
        require(_allowedList[msg.sender].remainingMints > 0, "b:06");
        
        uint256 tokenId = totalSupply();
        
        _tokenDataIndex.push(tokenData);
        
        TokenMetadata memory metadata;
        metadata.name = name;
        metadata.remainingVariants = _maxNumVariants;
        metadata.creator = msg.sender;
        _allowedList[msg.sender].remainingMints--;
        _tokenMetadataIndex.push(metadata);
        
        _numOriginals++;
        
        _safeMint(msg.sender, tokenId);
    }
    
    function remainingNumOriginals() public view returns (uint8) {
        return _maxNumOriginals - _numOriginals;
    }
    
    function remainingNumMints(address _address) public view returns (uint8) {
        return _allowedList[_address].remainingMints;
    }
    
    function allowedNumOriginals() public pure returns (uint8) {
        return _maxNumOriginals;
    }
    
    function allowedNumVariants() public pure returns (uint8) {
        return _maxNumVariants;
    }
    
    function availableBalanceForCreator(address creatorAddress) public view returns (uint256) {
        return _allowedList[creatorAddress].availableBalance;
    }
    
    function withdrawAvailableBalance() public nonReentrant onlyAllowed {
        uint256 withdrawAmount = _allowedList[msg.sender].availableBalance;
        _allowedList[msg.sender].availableBalance = 0;
        payable(msg.sender).transfer(withdrawAmount);
    }
    
    function mintVariant(uint256 tokenIdA, uint256 tokenIdB) public nonReentrant payable {
        require(msg.value == 0.1 ether);
        require(published == true, "b:02");
        require(_exists(tokenIdA) && _exists(tokenIdB), "b:07");
        require(tokenIdA != tokenIdB, "b:08");
        require(tokenRemainingVariantsOf(tokenIdA) > 0, "b:09");
        require(tokenIsOriginal(tokenIdA) && tokenIsOriginal(tokenIdB), "b:10");
        
        // a given pair can only be minted once
        bytes32 pairHash = keccak256(abi.encodePacked(tokenIdA, tokenIdB));
        require(_tokenPairs[pairHash] == false, "b:11");
        
        uint256 variantTokenId = totalSupply();
        
        VariantParents memory parents;
        parents.tokenIdA = tokenIdA;
        parents.tokenIdB = tokenIdB;
        
        _tokenMetadataIndex[tokenIdA].remainingVariants--;
        
        // don't need to write real data here since we can assemble sibling data from parent data
        _tokenDataIndex.push(hex"00");
        
        TokenMetadata memory metadata;
        metadata.name = "";
        metadata.remainingVariants = 0;
        metadata.creator = msg.sender;
        _tokenMetadataIndex.push(metadata);
        
        _tokenParentIndex[variantTokenId] = parents;
        _tokenPairs[pairHash] = true;
        _safeMint(msg.sender, variantTokenId);
        
        _allowedList[_tokenMetadataIndex[tokenIdA].creator].availableBalance += 0.0875 ether;
        _allowedList[_tokenMetadataIndex[tokenIdB].creator].availableBalance += 0.0125 ether;
    }
    
    function tokenNameOf(uint256 tokenId) public view returns (string memory) {
        string memory name;
        if (tokenIsOriginal(tokenId)) {
            name = _tokenMetadataIndex[tokenId].name;
        } else {
            VariantParents memory parents = _tokenParentIndex[tokenId];
            name = string(abi.encodePacked(tokenNameOf(parents.tokenIdA), " ", tokenNameOf(parents.tokenIdB)));
        }
        
        string[] memory components = StringUtil.titleCase(name);
        string memory titleCaseName;
        for (uint8 i = 0; i < components.length; ++i) {
            if (i == 0) {
                titleCaseName = components[i];
            } else {
                titleCaseName = string(abi.encodePacked(titleCaseName, " ", components[i]));
            }
        }
        
        return titleCaseName;
    }
    
    function tokenIsOriginal(uint256 tokenId) public view returns (bool) {
        return (_tokenDataIndex[tokenId].length == 268);
    }
    
    function tokenParentsOf(uint256 tokenId) public view returns (uint256, uint256) {
        require(!tokenIsOriginal(tokenId));
        return (_tokenParentIndex[tokenId].tokenIdA, _tokenParentIndex[tokenId].tokenIdB);
    }

    function tokenCreatorOf(uint256 tokenId) public view returns (address) {
        return _tokenMetadataIndex[tokenId].creator;
    }
    
    function tokenCreatorNameOf(uint256 tokenId) public view returns (string memory) {
        return _allowedList[tokenCreatorOf(tokenId)].name;
    }
    
    function tokenDataOf(uint256 tokenId) public view returns (bytes memory) {
        bytes memory data = _tokenDataIndex[tokenId];
        if (tokenIsOriginal(tokenId)) {
            return data;
        }
        
        bytes memory tokenParentData = _tokenDataIndex[_tokenParentIndex[tokenId].tokenIdA];
        bytes memory tokenPaletteData = _tokenDataIndex[_tokenParentIndex[tokenId].tokenIdB];
        for (uint8 i = 0; i < 12; ++i) {
            // overwrite palette data with parent B's palette data
            tokenParentData[i] = tokenPaletteData[i];
        }
        
        return tokenParentData;
    }
    
    function tokenRemainingVariantsOf(uint256 tokenId) public view returns (uint256) {
        if (!tokenIsOriginal(tokenId)) {
            return 0;
        }
        return _tokenMetadataIndex[tokenId].remainingVariants;
    }
    
    function uintToHexDigit(uint8 d) internal pure returns (bytes1) {
        if (0 <= d && d <= 9) {
            return bytes1(uint8(bytes1('0')) + d);
        } else if (10 <= uint8(d) && uint8(d) <= 15) {
            return bytes1(uint8(bytes1('a')) + d - 10);
        }
        revert();
    }
    
    function uintToHexString(uint a) internal pure returns (string memory) {
        uint count = 0;
        uint b = a;
        while (b != 0) {
            count++;
            b /= 16;
        }
        bytes memory res = new bytes(count);
        for (uint i=0; i<count; ++i) {
            b = a % 16;
            res[count - i - 1] = uintToHexDigit(uint8(b));
            a /= 16;
        }
        
        string memory str = string(res);
        if (bytes(str).length == 0) {
            return "00";
        } else if (bytes(str).length == 1) {
            return string(abi.encodePacked("0", str));
        }
        return str;
    }
    
    function byteToUint(bytes1 b) internal pure returns (uint) {
        return uint(uint8(b));
    }
    
    function byteToHexString(bytes1 b) internal pure returns (string memory) {
        return uintToHexString(byteToUint(b));
    }
    
    function bitTest(bytes1 aByte, uint8 index) internal pure returns (bool) {
        return uint8(aByte) >> index & 1 == 1;
    }
    
    function colorIndex(bytes1 aByte, uint8 index1, uint8 index2) internal pure returns (uint) {
        if (bitTest(aByte, index2) && bitTest(aByte, index1)) {
            return 3;
        } else if (bitTest(aByte, index2) && !bitTest(aByte, index1)) {
            return 2;
        } else if (!bitTest(aByte, index2) && bitTest(aByte, index1)) {
            return 1;
        }
        return 0;
    }
    
    function pixel4(string[32] memory lookup, SVGCursor memory pos) internal pure returns (string memory) {
        return string(abi.encodePacked(
            '<rect fill="', pos.color1, '" x="', lookup[pos.x], '" y="', lookup[pos.y], '" width="1.5" height="1.5" />', 
            '<rect fill="', pos.color2, '" x="', lookup[pos.x + 1], '" y="', lookup[pos.y], '" width="1.5" height="1.5" />',
            
            string(abi.encodePacked(
                '<rect fill="', pos.color3, '" x="', lookup[pos.x + 2], '" y="', lookup[pos.y], '" width="1.5" height="1.5" />', 
                '<rect fill="', pos.color4, '" x="', lookup[pos.x + 3], '" y="', lookup[pos.y], '" width="1.5" height="1.5" />'
            ))
        ));
    }
    
    function tokenSvgDataOf(uint256 tokenId) public view returns (string memory) {
        string memory svgString = '<?xml version="1.0" encoding="UTF-8" standalone="no"?><svg xmlns="http://www.w3.org/2000/svg" version="1.1" viewBox="0 0 32 32">';
        
        string[32] memory lookup = [
            "0", "1", "2", "3", "4", "5", "6", "7", 
            "8", "9", "10", "11", "12", "13", "14", "15", 
            "16", "17", "18", "19", "20", "21", "22", "23", 
            "24", "25", "26", "27", "28", "29", "30", "31"
        ];
        
        SVGCursor memory pos;
        
        bytes memory data = tokenDataOf(tokenId);
        
        string[4] memory colors = [
            string(abi.encodePacked("#", byteToHexString(data[0]), byteToHexString(data[1]), byteToHexString(data[2]))),
            string(abi.encodePacked("#", byteToHexString(data[3]), byteToHexString(data[4]), byteToHexString(data[5]))),
            string(abi.encodePacked("#", byteToHexString(data[6]), byteToHexString(data[7]), byteToHexString(data[8]))),
            string(abi.encodePacked("#", byteToHexString(data[9]), byteToHexString(data[10]), byteToHexString(data[11])))       
        ];
        
        string[8] memory p;

        for (uint i = 12; i < 268; i += 8) {
            pos.color1 =  colors[colorIndex(data[i], 6, 7)];
            pos.color2 =  colors[colorIndex(data[i], 4, 5)];
            pos.color3 =  colors[colorIndex(data[i], 2, 3)];
            pos.color4 =  colors[colorIndex(data[i], 0, 1)];
            p[0] = pixel4(lookup, pos);
            pos.x += 4;
            
            pos.color1 =  colors[colorIndex(data[i + 1], 6, 7)];
            pos.color2 =  colors[colorIndex(data[i + 1], 4, 5)];
            pos.color3 =  colors[colorIndex(data[i + 1], 2, 3)];
            pos.color4 =  colors[colorIndex(data[i + 1], 0, 1)];
            p[1] = pixel4(lookup, pos);
            pos.x += 4;
            
            pos.color1 =  colors[colorIndex(data[i + 2], 6, 7)];
            pos.color2 =  colors[colorIndex(data[i + 2], 4, 5)];
            pos.color3 =  colors[colorIndex(data[i + 2], 2, 3)];
            pos.color4 =  colors[colorIndex(data[i + 2], 0, 1)];
            p[2] = pixel4(lookup, pos);
            pos.x += 4;
            
            pos.color1 =  colors[colorIndex(data[i + 3], 6, 7)];
            pos.color2 =  colors[colorIndex(data[i + 3], 4, 5)];
            pos.color3 =  colors[colorIndex(data[i + 3], 2, 3)];
            pos.color4 =  colors[colorIndex(data[i + 3], 0, 1)];
            p[3] = pixel4(lookup, pos);
            pos.x += 4;
            
            pos.color1 =  colors[colorIndex(data[i + 4], 6, 7)];
            pos.color2 =  colors[colorIndex(data[i + 4], 4, 5)];
            pos.color3 =  colors[colorIndex(data[i + 4], 2, 3)];
            pos.color4 =  colors[colorIndex(data[i + 4], 0, 1)];
            p[4] = pixel4(lookup, pos);
            pos.x += 4;
            
            pos.color1 =  colors[colorIndex(data[i + 5], 6, 7)];
            pos.color2 =  colors[colorIndex(data[i + 5], 4, 5)];
            pos.color3 =  colors[colorIndex(data[i + 5], 2, 3)];
            pos.color4 =  colors[colorIndex(data[i + 5], 0, 1)];
            p[5] = pixel4(lookup, pos);
            pos.x += 4;
            
            pos.color1 =  colors[colorIndex(data[i + 6], 6, 7)];
            pos.color2 =  colors[colorIndex(data[i + 6], 4, 5)];
            pos.color3 =  colors[colorIndex(data[i + 6], 2, 3)];
            pos.color4 =  colors[colorIndex(data[i + 6], 0, 1)];
            p[6] = pixel4(lookup, pos);
            pos.x += 4;
            
            pos.color1 =  colors[colorIndex(data[i + 7], 6, 7)];
            pos.color2 =  colors[colorIndex(data[i + 7], 4, 5)];
            pos.color3 =  colors[colorIndex(data[i + 7], 2, 3)];
            pos.color4 =  colors[colorIndex(data[i + 7], 0, 1)];
            p[7] = pixel4(lookup, pos);
            pos.x += 4;
            
            svgString = string(abi.encodePacked(svgString, p[0], p[1], p[2], p[3], p[4], p[5], p[6], p[7]));
            
            if (pos.x >= 32) {
                pos.x = 0;
                pos.y += 1;
            }
        }
        
        svgString = string(abi.encodePacked(svgString, "</svg>"));
        return svgString;
    }
    
    function tokenRGBColorsOf(uint256 tokenId) public view returns (BlitmapAnalysis.Colors memory) {
        return BlitmapAnalysis.tokenRGBColorsOf(tokenDataOf(tokenId));
    }
    
    function tokenSlabsOf(uint256 tokenId) public view returns (string[4] memory) {
        return BlitmapAnalysis.tokenSlabsOf(tokenDataOf(tokenId));
    }
    
    function tokenAffinityOf(uint256 tokenId) public view returns (string[3] memory) {
        return BlitmapAnalysis.tokenAffinityOf(tokenDataOf(tokenId));
    }
}

/*               
errors:         
01: This can only be done before the project has been published.
02: This can only be done after the project has been published.
03: The maximum number of originals has been minted.
04: Blitmaps must be exactly 268 bytes.
05: Blitmaps must have a title must be between 1 and 10 characters.
06: You have reached your quota for minted originals.
07: One of the originals in this combination doesn't exist.
08: An original cannot be combined with itself.
09: This original has sold out all of its siblings.
10: Both blitmaps in this combination must be originals.
11: A sibling with this combination already exists.
*/