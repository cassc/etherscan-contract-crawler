// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

/** 
 * XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
 * XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
 * XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX  .***   XXXXXXXXXXXXXXXXXXXXXXXXXXXXX
 * XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX  ,*********  XXXXXXXXXXXXXXXXXXXXXXXXXXX
 * XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX  ***************  XXXXXXXXXXXXXXXXXXXXXXXX
 * XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX  .*******************  XXXXXXXXXXXXXXXXXXXXXX
 * XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX  ***********    **********  XXXXXXXXXXXXXXXXXXX
 * XXXXXXXXXXXXXXXXXXXXXXXXXXXXXX   ***********       ***********  XXXXXXXXXXXXXXXXX
 * XXXXXXXXXXXXXXXXXXXXXXXXXXXX  ***********         ***************  XXXXXXXXXXXXXX
 * XXXXXXXXXXXXXXXXXXXXXXXXXX  ***********           ****    ********* XXXXXXXXXXXXX
 * XXXXXXXXXXXXXXXXXXXXXXXXXX *********      ***    ***      *********  XXXXXXXXXXXX
 * XXXXXXXXXXXXXXXXXXXXXXXXXX  **********  *****          *********** XXXXXXXXXXXXXX
 * XXXXXXXXXXXXXXXXXXXXXX   /////.*************         ***********  XXXXXXXXXXXXXXX
 * XXXXXXXXXXXXXXXXXXX  /////////...***********      ************  XXXXXXXXXXXXXXXXX
 * XXXXXXXXXXXXXXXXX/ ///////////..... /////////   ///////////   XXXXXXXXXXXXXXXXXXX
 * XXXXXXXXXXXXXXXX  /    //////.........///////////////////   XXXXXXXXXXXXXXXXXXXXX
 * XXXXXXXXXXXXXXXXXXXX .///////...........//////////////   XXXXXXXXXXXXXXXXXXXXXXXX
 * XXXXXXXXXXXXXXXXXXX .///////.....//..////  /////////  XXXXXXXXXXXXXXXXXXXXXXXXXXX
 * XXXXXXXXXXXXXXXXX# /////////////////////  XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
 * XXXXXXXXXXXXXXX   ////////////////////   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
 * XXXXXXXXXXXX   ////////////// //////   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
 * XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
 * XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
 */

import {ABDKMath64x64} from "../util/ABDKMath64x64.sol";
import {Base64} from "../util/Base64.sol";
import {Roots} from "../util/Roots.sol";
import {Strings} from "../util/Strings.sol";

interface IMergeMetadata {    
    function tokenMetadata(
        uint256 tokenId, 
        uint256 rarity, 
        uint256 tokenMass, 
        uint256 alphaMass, 
        bool isAlpha, 
        uint256 mergeCount) external view returns (string memory);
}

contract MergeMetadata is IMergeMetadata {
    
    struct ERC721MetadataStructure {
        bool isImageLinked;
        string name;
        string description;
        string createdBy;
        string image;
        ERC721MetadataAttribute[] attributes;
    }

    struct ERC721MetadataAttribute {
        bool includeDisplayType;
        bool includeTraitType;
        bool isValueAString;
        string displayType;
        string traitType;
        string value;
    }
    
    using ABDKMath64x64 for int128;    
    using Base64 for string;
    using Roots for uint;    
    using Strings for uint256;    
    
    address public owner;  

    string private _name;
    string private _imageBaseURI;
    string private _imageExtension;
    uint256 private _maxRadius;
    string[] private _imageParts;
    mapping (string => string) private _classStyles;
  
    string constant private _RADIUS_TAG = '<RADIUS>';
    string constant private _CLASS_TAG = '<CLASS>';  
    string constant private _CLASS_STYLE_TAG = '<CLASS_STYLE>';  
  
    constructor() {
        owner = msg.sender;
        _name = "m";
        _imageBaseURI = ""; // Set to empty string - results in on-chain SVG generation by default unless this is set later
        _imageExtension = ""; // Set to empty string - can be changed later to remain empty, .png, .mp4, etc
        _maxRadius = 1000;

        // Deploy with default SVG image parts - can be completely replaced later
        _imageParts.push("<svg xmlns='http://www.w3.org/2000/svg' version='1.1' width='2000' height='2000'>");
            _imageParts.push("<style>");
                _imageParts.push(".m1 #c{fill: #fff;}");
                _imageParts.push(".m1 #r{fill: #000;}");
                _imageParts.push(".m2 #c{fill: #fc3;}");
                _imageParts.push(".m2 #r{fill: #000;}");
                _imageParts.push(".m3 #c{fill: #fff;}");
                _imageParts.push(".m3 #r{fill: #33f;}");
                _imageParts.push(".m4 #c{fill: #fff;}");
                _imageParts.push(".m4 #r{fill: #f33;}");
                _imageParts.push(".a #c{fill: #000 !important;}");
                _imageParts.push(".a #r{fill: #fff !important;}");
                _imageParts.push(_CLASS_STYLE_TAG);
            _imageParts.push("</style>");
            _imageParts.push("<g class='");
                _imageParts.push(_CLASS_TAG);
                _imageParts.push("'>");
                    _imageParts.push("<rect id='r' width='2000' height='2000'/>");
                    _imageParts.push("<circle id='c' cx='1000' cy='1000' r='");
                        _imageParts.push(_RADIUS_TAG);
                    _imageParts.push("'/>");
            _imageParts.push("</g>");                
        _imageParts.push("</svg>");
    }        
    
    function setName(string calldata name_) external { 
        _requireOnlyOwner();       
        _name = name_;
    }

    function setImageBaseURI(string calldata imageBaseURI_, string calldata imageExtension_) external {        
        _requireOnlyOwner();
        _imageBaseURI = imageBaseURI_;
        _imageExtension = imageExtension_;
    }

    function setMaxRadius(uint256 maxRadius_) external {
        _requireOnlyOwner();
        _maxRadius = maxRadius_;
    }    

    function tokenMetadata(uint256 tokenId, uint256 rarity, uint256 tokenMass, uint256 alphaMass, bool isAlpha, uint256 mergeCount) external view override returns (string memory) {        
        string memory base64Json = Base64.encode(bytes(string(abi.encodePacked(_getJson(tokenId, rarity, tokenMass, alphaMass, isAlpha, mergeCount)))));
        return string(abi.encodePacked('data:application/json;base64,', base64Json));
    }

    function updateImageParts(string[] memory imageParts_) public {
        _requireOnlyOwner();
        _imageParts = imageParts_;
    }

    function updateClassStyle(string calldata cssClass, string calldata cssStyle) external {
        _requireOnlyOwner();
        _classStyles[cssClass] = cssStyle;
    }

    function getClassStyle(string memory cssClass) public view returns (string memory) {
        return _classStyles[cssClass];
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function imageBaseURI() public view returns (string memory) {
        return _imageBaseURI;
    }

    function imageExtension() public view returns (string memory) {
        return _imageExtension;
    }

    function maxRadius() public view returns (uint256) {
        return _maxRadius;
    }            

    function getClassString(uint256 tokenId, uint256 rarity, bool isAlpha, bool offchainImage) public pure returns (string memory) {
        return _getClassString(tokenId, rarity, isAlpha, offchainImage);
    }

    function _getJson(uint256 tokenId, uint256 rarity, uint256 tokenMass, uint256 alphaMass, bool isAlpha, uint256 mergeCount) private view returns (string memory) {        
        string memory imageData = 
            bytes(_imageBaseURI).length == 0 ? 
                _getSvg(tokenId, rarity, tokenMass, alphaMass, isAlpha) :
                string(abi.encodePacked(imageBaseURI(), _getClassString(tokenId, rarity, isAlpha, true), "_", uint256(int256(_getScaledRadius(tokenMass, alphaMass, _maxRadius).toInt())).toString(), imageExtension()));

        ERC721MetadataStructure memory metadata = ERC721MetadataStructure({
            isImageLinked: bytes(_imageBaseURI).length > 0, 
            name: string(abi.encodePacked(name(), "(", tokenMass.toString(), ") #", tokenId.toString())),
            description: tokenMass.toString(),
            createdBy: "Pak",
            image: imageData,
            attributes: _getJsonAttributes(tokenId, rarity, tokenMass, mergeCount, isAlpha)
        });

        return _generateERC721Metadata(metadata);
    }        

    function _getJsonAttributes(uint256 tokenId, uint256 rarity, uint256 tokenMass, uint256 mergeCount, bool isAlpha) private pure returns (ERC721MetadataAttribute[] memory) {
        uint256 tensDigit = tokenId % 100 / 10;
        uint256 onesDigit = tokenId % 10;
        uint256 class = tensDigit * 10 + onesDigit;

        ERC721MetadataAttribute[] memory metadataAttributes = new ERC721MetadataAttribute[](5);
        metadataAttributes[0] = _getERC721MetadataAttribute(false, true, false, "", "Mass", tokenMass.toString());
        metadataAttributes[1] = _getERC721MetadataAttribute(false, true, false, "", "Alpha", isAlpha ? "1" : "0");
        metadataAttributes[2] = _getERC721MetadataAttribute(false, true, false, "", "Tier", rarity.toString());
        metadataAttributes[3] = _getERC721MetadataAttribute(false, true, false, "", "Class", class.toString());
        metadataAttributes[4] = _getERC721MetadataAttribute(false, true, false, "", "Merges", mergeCount.toString());
        return metadataAttributes;
    }    

    function _getERC721MetadataAttribute(bool includeDisplayType, bool includeTraitType, bool isValueAString, string memory displayType, string memory traitType, string memory value) private pure returns (ERC721MetadataAttribute memory) {
        ERC721MetadataAttribute memory attribute = ERC721MetadataAttribute({
            includeDisplayType: includeDisplayType,
            includeTraitType: includeTraitType,
            isValueAString: isValueAString,
            displayType: displayType,
            traitType: traitType,
            value: value
        });

        return attribute;
    }    

    function _getSvg(uint256 tokenId, uint256 rarity, uint256 tokenMass, uint256 alphaMass, bool isAlpha) private view returns (string memory) {
        bytes memory byteString;
        for (uint i = 0; i < _imageParts.length; i++) {
          if (_checkTag(_imageParts[i], _RADIUS_TAG)) {
            byteString = abi.encodePacked(byteString, _floatToString(_getScaledRadius(tokenMass, alphaMass, _maxRadius)));
          } else if (_checkTag(_imageParts[i], _CLASS_TAG)) {
            byteString = abi.encodePacked(byteString, _getClassString(tokenId, rarity, isAlpha, false));
          } else if (_checkTag(_imageParts[i], _CLASS_STYLE_TAG)) {
              uint256 tensDigit = tokenId % 100 / 10;
              uint256 onesDigit = tokenId % 10;
              uint256 class = tensDigit * 10 + onesDigit;
              string memory classCss = getClassStyle(_getTokenIdClass(class));
              if(bytes(classCss).length > 0) {
                  byteString = abi.encodePacked(byteString, classCss);
              }            
          } else {
            byteString = abi.encodePacked(byteString, _imageParts[i]);
          }
        }
        return string(byteString); 
    }

    function _getScaledRadius(uint256 tokenMass, uint256 alphaMass, uint256 maximumRadius) private pure returns (int128) {
        int128 radiusMass = _getRadius64x64(tokenMass);
        int128 radiusAlphaMass = _getRadius64x64(alphaMass);
        int128 scalePercentage = ABDKMath64x64.div(radiusMass, radiusAlphaMass);                
        int128 scaledRadius = ABDKMath64x64.mul(ABDKMath64x64.fromUInt(maximumRadius), scalePercentage);
        if(uint256(int256(scaledRadius.toInt())) == 0) {
            scaledRadius = ABDKMath64x64.fromUInt(1);
        }
        return scaledRadius;
    }

    // Radius = Cube Root(Mass) * Cube Root (0.23873241463)
    // Radius = Cube Root(Mass) * 0.62035049089
    function _getRadius64x64(uint256 mass) private pure returns (int128) {        
        int128 cubeRootScalar = ABDKMath64x64.divu(62035049089, 100000000000);
        int128 cubeRootMass = ABDKMath64x64.divu(mass.nthRoot(3, 6, 32), 1000000);
        int128 radius = ABDKMath64x64.mul(cubeRootMass, cubeRootScalar);        
        return radius;
    }            

    function _generateERC721Metadata(ERC721MetadataStructure memory metadata) private pure returns (string memory) {
      bytes memory byteString;    
    
        byteString = abi.encodePacked(
          byteString,
          _openJsonObject());
    
        byteString = abi.encodePacked(
          byteString,
          _pushJsonPrimitiveStringAttribute("name", metadata.name, true));
    
        byteString = abi.encodePacked(
          byteString,
          _pushJsonPrimitiveStringAttribute("description", metadata.description, true));
    
        byteString = abi.encodePacked(
          byteString,
          _pushJsonPrimitiveStringAttribute("created_by", metadata.createdBy, true));
    
        if(metadata.isImageLinked) {
            byteString = abi.encodePacked(
                byteString,
                _pushJsonPrimitiveStringAttribute("image", metadata.image, true));
        } else {
            byteString = abi.encodePacked(
                byteString,
                _pushJsonPrimitiveStringAttribute("image_data", metadata.image, true));
        }

        byteString = abi.encodePacked(
          byteString,
          _pushJsonComplexAttribute("attributes", _getAttributes(metadata.attributes), false));
    
        byteString = abi.encodePacked(
          byteString,
          _closeJsonObject());
    
        return string(byteString);
    }

    function _getAttributes(ERC721MetadataAttribute[] memory attributes) private pure returns (string memory) {
        bytes memory byteString;
    
        byteString = abi.encodePacked(
          byteString,
          _openJsonArray());
    
        for (uint i = 0; i < attributes.length; i++) {
          ERC721MetadataAttribute memory attribute = attributes[i];

          byteString = abi.encodePacked(
            byteString,
            _pushJsonArrayElement(_getAttribute(attribute), i < (attributes.length - 1)));
        }
    
        byteString = abi.encodePacked(
          byteString,
          _closeJsonArray());
    
        return string(byteString);
    }

    function _getAttribute(ERC721MetadataAttribute memory attribute) private pure returns (string memory) {
        bytes memory byteString;
        
        byteString = abi.encodePacked(
          byteString,
          _openJsonObject());
    
        if(attribute.includeDisplayType) {
          byteString = abi.encodePacked(
            byteString,
            _pushJsonPrimitiveStringAttribute("display_type", attribute.displayType, true));
        }
    
        if(attribute.includeTraitType) {
          byteString = abi.encodePacked(
            byteString,
            _pushJsonPrimitiveStringAttribute("trait_type", attribute.traitType, true));
        }
    
        if(attribute.isValueAString) {
          byteString = abi.encodePacked(
            byteString,
            _pushJsonPrimitiveStringAttribute("value", attribute.value, false));
        } else {
          byteString = abi.encodePacked(
            byteString,
            _pushJsonPrimitiveNonStringAttribute("value", attribute.value, false));
        }
    
        byteString = abi.encodePacked(
          byteString,
          _closeJsonObject());
    
        return string(byteString);
    }

    function _getClassString(uint256 tokenId, uint256 rarity, bool isAlpha, bool offchainImage) private pure returns (string memory) {
        bytes memory byteString;    
    
        byteString = abi.encodePacked(byteString, _getRarityClass(rarity));
        
        if(isAlpha) {
            byteString = abi.encodePacked(
              byteString,
              string(abi.encodePacked(offchainImage ? "_" : " ", "a")));
        }

        uint256 tensDigit = tokenId % 100 / 10;
        uint256 onesDigit = tokenId % 10;
        uint256 class = tensDigit * 10 + onesDigit;

        byteString = abi.encodePacked(
          byteString,
          string(abi.encodePacked(offchainImage ? "_" : " ", _getTokenIdClass(class))));

        return string(byteString);    
    }

    function _getRarityClass(uint256 rarity) private pure returns (string memory) {
        return string(abi.encodePacked("m", rarity.toString()));
    }

    function _getTokenIdClass(uint256 class) private pure returns (string memory) {
        return string(abi.encodePacked("c", class.toString()));
    }

    function _checkTag(string storage a, string memory b) private pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    function _floatToString(int128 value) private pure returns (string memory) {
        uint256 decimal4 = (value & 0xFFFFFFFFFFFFFFFF).mulu(10000);
        return string(abi.encodePacked(uint256(int256(value.toInt())).toString(), '.', _decimal4ToString(decimal4)));
    }
  
    function _decimal4ToString(uint256 decimal4) private pure returns (string memory) {
        bytes memory decimal4Characters = new bytes(4);
        for (uint i = 0; i < 4; i++) {
          decimal4Characters[3 - i] = bytes1(uint8(0x30 + decimal4 % 10));
          decimal4 /= 10;
        }
        return string(abi.encodePacked(decimal4Characters));
    }

    function _requireOnlyOwner() private view {
        require(msg.sender == owner, "You are not the owner");
    }

    function _openJsonObject() private pure returns (string memory) {        
        return string(abi.encodePacked("{"));
    }

    function _closeJsonObject() private pure returns (string memory) {
        return string(abi.encodePacked("}"));
    }

    function _openJsonArray() private pure returns (string memory) {        
        return string(abi.encodePacked("["));
    }

    function _closeJsonArray() private pure returns (string memory) {        
        return string(abi.encodePacked("]"));
    }

    function _pushJsonPrimitiveStringAttribute(string memory key, string memory value, bool insertComma) private pure returns (string memory) {
        return string(abi.encodePacked('"', key, '": "', value, '"', insertComma ? ',' : ''));
    }

    function _pushJsonPrimitiveNonStringAttribute(string memory key, string memory value, bool insertComma) private pure returns (string memory) {
        return string(abi.encodePacked('"', key, '": ', value, insertComma ? ',' : ''));
    }

    function _pushJsonComplexAttribute(string memory key, string memory value, bool insertComma) private pure returns (string memory) {
        return string(abi.encodePacked('"', key, '": ', value, insertComma ? ',' : ''));
    }

    function _pushJsonArrayElement(string memory value, bool insertComma) private pure returns (string memory) {
        return string(abi.encodePacked(value, insertComma ? ',' : ''));
    }
}