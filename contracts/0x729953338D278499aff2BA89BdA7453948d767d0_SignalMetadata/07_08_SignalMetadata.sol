// SPDX-License-Identifier: MIT
// base64.tech
pragma solidity ^0.8.13;
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Base64.sol";
import { Ordinal } from "./BTC721.sol";
import 'hardhat/console.sol';

/*

*/
contract SignalMetadata is Ownable
{
    using Strings for bytes;
    using Strings for uint256;
    string public baseImageURL;
    string public baseOrdinalURL;
    string public preRevealImageURL;
    string private preRevealInscriptionId;

    struct Trait {
        string traitType;
        string[] traitValues;
    }

    Trait[] traits;
    
    constructor() 
    {}


    function getBaseImageURL() external view returns(string memory) {
       return baseImageURL;
    }

    function getPreRevealMetadataString(uint256 _tokenId) public view returns (string memory) {
        return string(abi.encodePacked(
                            '{"name":"Signal # ',
                            _tokenId.toString(),
                            '","description":"Signal.exe is a generative art project exploring the relationship between order and chaos, information and distortion. A visual representation of the dynamic interplay between structured signals and random noise, the work is a display of abstract patterns geometric forms. Signal.exe captures the essence of randomness and order, revealing the beauty that lies hidden within the chaos. ", "image": "',
                            preRevealImageURL,
                            '"}'
        ));
    }

    function getEncodedTraitsString(uint32[8] memory _traitsIndices) public view returns (string memory) {
        string memory retVal;

        if (_traitsIndices[0] != 0) {
             retVal = string(abi.encodePacked(
                            '{"trait_type":"',
                            traits[0].traitType,
                            '","value":"',
                            traits[0].traitValues[_traitsIndices[0]],
                            '"}'                            
            ));
        } 
        if(_traitsIndices[1] != 0) {
            if (bytes(retVal).length > 0) {
                retVal = string(abi.encodePacked(retVal,","));
            }

            retVal = string(abi.encodePacked(
                            retVal,
                            '{"trait_type":"',
                            traits[1].traitType,
                            '","value":"',
                            traits[1].traitValues[_traitsIndices[1]],
                            '"}'          
            ));
        }

        return retVal;    
    }       

    function getMetadataString(uint256 _tokenId, Ordinal memory _ordinal,uint32[8] memory _traits) public view returns (string memory) {
        return string(abi.encodePacked(
                        '{"name":"Signal # ',
                        _tokenId.toString(),
                        '","description":"Direct link to the Ordinal where this image is stored: ',
                        baseOrdinalURL, '/', _ordinal.inscriptionId, 
                        '\\n\\nSignal.exe is a generative art project exploring the relationship between order and chaos, information and distortion. A visual representation of the dynamic interplay between structured signals and random noise, the work is a display of abstract patterns geometric forms. Signal.exe captures the essence of randomness and order, revealing the beauty that lies hidden within the chaos.","attributes":[{"trait_type":"Inscription #","value":"',
                        _ordinal.inscriptionNum.toString(),
                        '"},{"trait_type":"InscriptionId","value":"',
                        _ordinal.inscriptionId,
                        '"},',
                        getEncodedTraitsString(_traits),
                        '], "image": "',
                        baseImageURL,
                        '/',
                        _ordinal.inscriptionId,
                        '"}'
        ));
    }
    
    function getMetadata(uint256 _tokenId, Ordinal memory _ordinal, uint32[8] memory _traits) public view returns (string memory) {
        string memory metadata;

        if(bytes(_ordinal.inscriptionId).length == 0) {
            metadata = getPreRevealMetadataString(_tokenId);
        } else {
            metadata = getMetadataString(_tokenId, _ordinal, _traits);
        }
        
        return string(abi.encodePacked('data:application/json;base64,', Base64.encode(bytes(metadata))));
    }

    /* ONLY OWNER FUNCTIONS */
    function setBaseOrdinalURL(string calldata baseURL) external onlyOwner {
        baseOrdinalURL = baseURL;
    }

    function setBaseImageURL(string calldata baseURL) external onlyOwner {
        baseImageURL = baseURL;
    }

    function setPreRevealImageURL(string calldata baseURL) external onlyOwner {
        preRevealImageURL = baseURL;
    }


    function setTraits(Trait[] memory _traits) external onlyOwner {
        
        for(uint256 i; i < _traits.length; i++) {
            string[] memory traitValues = new string[]  (_traits[i].traitValues.length);
            
            for(uint256 j; j < _traits[i].traitValues.length; j++) {
                traitValues[j] = _traits[i].traitValues[j];
            }
            
            traits.push(Trait(_traits[i].traitType, traitValues));
        }
    }

}

error BadInputData();