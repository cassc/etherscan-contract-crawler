// SPDX-License-Identifier: MIT
// base64.tech
pragma solidity ^0.8.13;
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Base64.sol";

/*
   ▄██████▄     ▄████████  ▄█    ▄▄▄▄███▄▄▄▄   
  ███    ███   ███    ███ ███  ▄██▀▀▀███▀▀▀██▄ 
  ███    █▀    ███    ███ ███▌ ███   ███   ███ 
 ▄███         ▄███▄▄▄▄██▀ ███▌ ███   ███   ███ 
▀▀███ ████▄  ▀▀███▀▀▀▀▀   ███▌ ███   ███   ███ 
  ███    ███ ▀███████████ ███  ███   ███   ███ 
  ███    ███   ███    ███ ███  ███   ███   ███ 
  ████████▀    ███    ███ █▀    ▀█   ███   █▀  
               ███    ███                      
                    METADATA                               
*/
contract GrimMetadata is Ownable
{
    using Strings for bytes;
    using Strings for uint256;
    string private baseURI;

    constructor(){}


    function setBaseURI(string calldata _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function getMetadata(uint256 _tokenId) public view returns (string memory) {
        string memory metadataReference;

        if (_tokenId < 100) {
            metadataReference = "elemental";
        } else if (_tokenId >= 100 && _tokenId < 200) {
            metadataReference = "decay";
        } else if (_tokenId >= 200 && _tokenId < 300) {
            metadataReference = "sacrificial";
        }

        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, metadataReference, ".json")) : '';
    }

}