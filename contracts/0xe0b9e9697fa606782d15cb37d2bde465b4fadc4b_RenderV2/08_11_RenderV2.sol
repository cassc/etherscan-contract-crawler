// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;


import "openzeppelin/access/Ownable.sol";
import { Strings} from "openzeppelin/utils/Strings.sol";
import { Base64 } from "solady/utils/Base64.sol";
import 'ethier/utils/DynamicBuffer.sol';
import {SharedStructs as SSt} from "./sharedStructs.sol";
import "./interfaces/IIndelible.sol";
import {IGenericRender} from "./interfaces/IGenericRender.sol";
import "forge-std/console.sol";

interface IMash {
    function getCollection(uint256 _collectionNr) external view returns(SSt.CollectionInfo memory);
    function getLayerNames(uint256 collectionNr) external view returns(string[] memory);
}

interface IBlitmap {
    function tokenNameOf(uint256 tokenId) external view returns(string memory);
    function tokenSvgDataOf(uint256 tokenId) external view returns(string memory);
}

interface IKevin {
    function traitTypes(uint256 layer, uint256 trait, uint256 selector) external view returns(string memory);
}

interface INounsDescriptorV2 {
    function palettes(uint8 paletteIndex) external view returns (bytes memory);
    function backgrounds(uint256 index) external view returns (string memory);
    function bodies(uint256 index) external view returns (bytes memory);
    function accessories(uint256 index) external view returns (bytes memory);
    function heads(uint256 index) external view returns (bytes memory);
    function glasses(uint256 index) external view returns (bytes memory);
}

interface ISVGRenderer {
    struct Part {
        bytes image;
        bytes palette;
    }
    function generateSVGPart(Part memory part) external view returns (string memory partialSVG);
}

contract RenderV2 is Ownable, SSt {
    using Strings for uint256;
    using DynamicBuffer for bytes;

    uint256 public constant MAX_LAYERS = 7; 

    IMash public mash;

    uint24[7] colors = [0xe1d7d5, 0xfbe3ab, 0x72969e, 0xd51e29, 0x174f87, 0x2afd2f, 0x621b62];

    struct CustomRenderer {
        address addr;
        bool base64Encoded; 
    }

    //Non indelible collections that need special treatment are here 
    address constant blitmap = 0x8d04a8c79cEB0889Bdd12acdF3Fa9D207eD3Ff63;
    address constant flipmap = 0x0E4B8e24789630618aA90072F520711D3d9Db647;
    address constant onChainKevin = 0xaC3AE179bB3c0edf2aB2892a2B6A4644A71627B6;
    address constant nounsToken = 0x9C8fF314C9Bc7F6e59A9d9225Fb22946427eDC03;
    //address constant chainRunners = 0x97597002980134beA46250Aa0510C9B90d87A587;
    INounsDescriptorV2 constant nounsDescriptor = INounsDescriptorV2(0x6229c811D04501523C6058bfAAc29c91bb586268);
    ISVGRenderer constant nounsRenderer = ISVGRenderer(0x81d94554A4b072BFcd850205f0c79e97c92aab56);

    //other contracts that are handled by a seperate renderer are in this mapping
    mapping (address => CustomRenderer) renderers;

    // constructor() {

    // }

    ////////////////////////  Setters /////////////////////////////////

    function setMash( address _newMash) external onlyOwner {
        mash = IMash(_newMash);
    }

    function setColore(uint24[7] calldata _newcolors) external onlyOwner {
        colors = _newcolors;
    }

    function addContract(address _collection, address _render, bool _base64Encoded) external onlyOwner {
        renderers[_collection] = CustomRenderer(_render, _base64Encoded);
    }

    ////////////////////////  Trait Data functions functions /////////////////////////////////

    function getTraitDetails(address _collection, uint8 layerId, uint8 traitId) public view returns(IIndelible.Trait memory) {
        uint16 id = (uint16(layerId) << 8) | uint16(traitId);
        if(_collection == blitmap) return IIndelible.Trait(IBlitmap(blitmap).tokenNameOf(id),"image/svg+xml");
        if(_collection == flipmap) return IIndelible.Trait(string.concat("Flipmap #", Strings.toString(id)), "image/svg+xml");
        if(_collection == onChainKevin) return IIndelible.Trait(IKevin(onChainKevin).traitTypes(layerId, traitId, 0), "image/png");
        if(_collection == nounsToken) return IIndelible.Trait(getNounsTraits(layerId, traitId), "image/svg+xml");
        if(renderers[_collection].addr != address(0)) return IGenericRender(renderers[_collection].addr).getTraitDetails(layerId, traitId);
        return IIndelible(_collection).traitDetails(layerId, traitId);
    }

    function getTraitData(address _collection, uint8 _layerId, uint8 _traitId) public view returns(bytes memory) {
        console.log("layer, trait, id");
        uint16 id = (uint16(_layerId) << 8) | uint16(_traitId);
        
        if(_collection == blitmap || _collection == flipmap) {
            return bytes(IBlitmap(_collection).tokenSvgDataOf(id));
        }
        if(_collection == onChainKevin) return bytes(IKevin(onChainKevin).traitTypes(_layerId, _traitId, 1));
        if(_collection == nounsToken) {
            return bytes(string.concat('<svg width="320" height="320" viewBox="0 0 320 320" xmlns="http://www.w3.org/2000/svg" shape-rendering="crispEdges">', getNounsData(_layerId, _traitId), '</svg>')); 
        }
        if(renderers[_collection].addr != address(0)) return IGenericRender(renderers[_collection].addr).getTraitData(_layerId, _traitId);
        return bytes(IIndelible(_collection).traitData(_layerId, _traitId));
    }

    function getCollectionName(address _collection) public view returns(string memory) {
        if(_collection == blitmap) return "Blitmap";
        if(_collection == flipmap) return "Flipmap";
        if(_collection == onChainKevin) return "On Chain Kevin";
        if(_collection == nounsToken) return "Nouns";
        if(renderers[_collection].addr != address(0)) return IGenericRender(renderers[_collection].addr).getCollectionName();
        (string memory out,,,,,,) = IIndelible(_collection).contractData();
        return out;
    }

    //// special collection functions
    function getNounsTraits(uint8 layerId, uint8 traitId) private pure returns (string memory) {
        if(layerId == 0) return string.concat("Body #", Strings.toString(traitId));
        if(layerId == 1) return string.concat("Accessory #", Strings.toString(traitId));
        if(layerId == 2) return string.concat("Head #", Strings.toString(traitId));
        return string.concat("Glasses #", Strings.toString(traitId));
    }
    
    function getNounsData(uint8 layerId, uint8 traitId) private view returns(string memory) {
        if(layerId == 0) return nounsRenderer.generateSVGPart( ISVGRenderer.Part (nounsDescriptor.bodies(traitId), nounsDescriptor.palettes(0)));
        if(layerId == 1) return nounsRenderer.generateSVGPart( ISVGRenderer.Part (nounsDescriptor.accessories(traitId), nounsDescriptor.palettes(0)));
        if(layerId == 2) return nounsRenderer.generateSVGPart( ISVGRenderer.Part (nounsDescriptor.heads(traitId), nounsDescriptor.palettes(0)));
        return nounsRenderer.generateSVGPart( ISVGRenderer.Part (nounsDescriptor.glasses(traitId), nounsDescriptor.palettes(0)));
    }

    ////////////////////////  TokenURI and preview /////////////////////////////////

    function tokenURI(uint256 tokenId, LayerStruct[MAX_LAYERS] memory layerInfo, CollectionInfo[MAX_LAYERS] memory _collections) external view returns (string memory) { 
        uint8 numberOfLayers = 0;
        string[MAX_LAYERS] memory collectionNames;
        IIndelible.Trait[MAX_LAYERS] memory traitNames;
        for(uint256 i = 0; i < layerInfo.length; i++) {
            if(layerInfo[i].collection == 0) continue;
            numberOfLayers++; 
            collectionNames[i] = getCollectionName(_collections[i].collection);
            traitNames[i] = getTraitDetails(_collections[i].collection, layerInfo[i].layerId, layerInfo[i].traitId);   
        }
        string memory _outString = string.concat('data:application/json,', '{', '"name" : "CC0 Mash #' , Strings.toString(tokenId), '", ',
            '"description" : "What Is This, a Crossover Episode?"');
        
        _outString = string.concat(_outString, ',"attributes":[');
        string[] memory layerNames; 
        for(uint8 i = 0; i < layerInfo.length; i++) {
            if(layerInfo[i].collection == 0) continue;
            layerNames = mash.getLayerNames(layerInfo[i].collection);
            if(i > 0) _outString = string.concat(_outString,',');
              _outString = string.concat(
              _outString,
             '{"trait_type":"', _collections[i].collection == blitmap ? "Blitmap" : _collections[i].collection == flipmap ? "Flipmap" :  layerNames[layerInfo[i].layerId], '","value":"', traitNames[i].name,' (from ', collectionNames[i] , ')"}'
             );
        }

        _outString = string.concat(_outString, ']');

        if(numberOfLayers != 0) {
            _outString = string.concat(_outString,',"image": "data:image/svg+xml;base64,',
                Base64.encode(_drawTraits(layerInfo, _collections, traitNames)), '"');
        }
        _outString = string.concat(_outString,'}');
        return _outString; 
    }

    function previewCollage(LayerStruct[MAX_LAYERS] memory layerInfo) external view returns(string memory) {
        uint8 numberOfLayers = 0;
        CollectionInfo[MAX_LAYERS] memory _collections;
        IIndelible.Trait[MAX_LAYERS] memory traitNames;
        for(uint256 i = 0; i < layerInfo.length; i++) {
            if(layerInfo[i].collection == 0) continue;
            _collections[i] = mash.getCollection(layerInfo[i].collection);
            traitNames[i] = getTraitDetails(_collections[i].collection, layerInfo[i].layerId, layerInfo[i].traitId);
            ++numberOfLayers;
        }
        return string(_drawTraits(layerInfo, _collections, traitNames));
    }

    // function getSVGForTrait(uint8 _collectionId, uint8 _layerId, uint8 _traitId) external view returns (string memory) {
    //     bytes memory buffer = DynamicBuffer.allocate(2**18);
    //     CollectionInfo memory _collectionInfo = mash.getCollection(_collectionId);
    //     bytes memory _traitData = getTraitData(_collectionInfo.collection, _layerId, _traitId);
    //     IIndelible.Trait memory _traitDetails = getTraitDetails(_collectionInfo.collection, _layerId, _traitId);
    //     buffer.appendSafe(bytes(string.concat('<image width="100%" height="100%" href="data:', _traitDetails.mimetype , ';base64,'))); //add the gif/png selector
    //     buffer.appendSafe(bytes(Base64.encode(_traitData)));
    //     buffer.appendSafe(bytes('"/>'));
    //     buffer.appendSafe('<style>#pixel {image-rendering: pixelated; image-rendering: -moz-crisp-edges; image-rendering: -webkit-crisp-edges; -ms-interpolation-mode: nearest-neighbor;}</style></svg>');
    //     return string(abi.encodePacked('<svg xmlns="http://www.w3.org/2000/svg" shape-rendering="crispEdges" version="1.1" id="pixel" viewBox="0 0 ', Strings.toString(_collectionInfo.xSize), ' ', Strings.toString(_collectionInfo.ySize),'" width="1200" height="1200"> ', buffer));
    // }

    ////////////////////////  SVG functions /////////////////////////////////

    function _drawTraits(LayerStruct[MAX_LAYERS] memory _layerInfo, CollectionInfo[MAX_LAYERS] memory _collections, IIndelible.Trait[MAX_LAYERS] memory traitNames) internal view returns(bytes memory) {
            bytes memory buffer = DynamicBuffer.allocate(2**18);
            //buffer.appendSafe(bytes(string.concat('<svg xmlns="http://www.w3.org/2000/svg" shape-rendering="crispEdges" version="1.1" viewBox="0 0 ', Strings.toString(height), ' ', Strings.toString(width),'" width="',Strings.toString(height*5),'" height="',Strings.toString(width*5),'"> ')));
            int256 height = int256(uint256(_collections[0].xSize*_layerInfo[0].scale));
            int256 width = int256(uint256(_collections[0].ySize*_layerInfo[0].scale));
            if(_layerInfo[0].background != 0) {
                buffer.appendSafe(bytes(string.concat('<rect width="100%" height="100%" fill="#', bytes2hex(colors[_layerInfo[0].background-1]) ,'" />')));
            }
            for(uint256 i = 0; i < _layerInfo.length; i++) {
                if(_layerInfo[i].collection == 0) continue;
                _renderImg(_layerInfo[i], _collections[i], traitNames[i], buffer);
                if(!_layerInfo[0].pfpRender) { 
                    if(int256(uint256(_collections[i].ySize*_layerInfo[i].scale))+_layerInfo[i].yOffset > height) height = int256(uint256(_collections[i].ySize*_layerInfo[i].scale))+_layerInfo[i].yOffset;
                    if(int256(uint256(_collections[i].xSize*_layerInfo[i].scale))+_layerInfo[i].xOffset > width) width = int256(uint256(_collections[i].xSize*_layerInfo[i].scale))+_layerInfo[i].xOffset;
                }
            }
            buffer.appendSafe('<style>#pixel {image-rendering: pixelated; image-rendering: -moz-crisp-edges; image-rendering: -webkit-crisp-edges; -ms-interpolation-mode: nearest-neighbor;}</style></svg>');
            return abi.encodePacked('<svg xmlns="http://www.w3.org/2000/svg" shape-rendering="crispEdges" version="1.1" id="pixel" viewBox="0 0 ', Strings.toString(uint256(width)), ' ', Strings.toString(uint256(height)),'" width="',Strings.toString(uint256(width)*20),'" height="',Strings.toString(uint256(height)*20),'"> ', buffer);
    }

    function _renderImg(LayerStruct memory _currentLayer, CollectionInfo memory _currentCollection, IIndelible.Trait memory traitNames, bytes memory buffer) private view {
        //currently only renders as PNG this should also include gif! 
        bytes memory _traitData = getTraitData(_currentCollection.collection, _currentLayer.layerId, _currentLayer.traitId);
        buffer.appendSafe(bytes(string.concat('<image x="', int8ToString(_currentLayer.xOffset), '" y="', int8ToString(_currentLayer.yOffset),'" width="', Strings.toString(_currentCollection.xSize*_currentLayer.scale), '" height="', Strings.toString(_currentCollection.ySize*_currentLayer.scale),
         '" href="data:', traitNames.mimetype , ';base64,')));
        buffer.appendSafe((_currentCollection.collection == onChainKevin || renderers[_currentCollection.collection].base64Encoded) ? _traitData : bytes(Base64.encode(_traitData)));
        buffer.appendSafe(bytes('"/>'));
    }

    function int8ToString(int8 num) internal pure returns (string memory) {
        return num < 0 ? string.concat("-", Strings.toString(uint8(-1 * num) )): Strings.toString(uint8(num));
    }

    function bytes2hex(uint24 u) internal pure returns (string memory) {
        bytes memory b = new bytes(6);
        for (uint256 j = 0; j < 6; j++) {
        b[5 - j] = _getHexChar(uint8(uint24(u) & 0x0f));
        u = u >> 4;
        }
    return string(b);
    }

    function _getHexChar(uint8 char) internal pure returns (bytes1) {
    return
      (char > 9)
        ? bytes1(char + 87) // ascii a-f
        : bytes1(char + 48); // ascii 0-9
    } 

}