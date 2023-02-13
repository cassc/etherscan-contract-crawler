// SPDX-License-Identifier: MIT
// base64.tech
pragma solidity ^0.8.13;
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Base64.sol";

/*

██▄   █▄▄▄▄ ▄███▄   ██   █▀▄▀█   ▄███▄      ▄  ▄███▄   
█  █  █  ▄▀ █▀   ▀  █ █  █ █ █   █▀   ▀ ▀▄   █ █▀   ▀  
█   █ █▀▀▌  ██▄▄    █▄▄█ █ ▄ █   ██▄▄     █ ▀  ██▄▄    
█  █  █  █  █▄   ▄▀ █  █ █   █   █▄   ▄▀ ▄ █   █▄   ▄▀ 
███▀    █   ▀███▀      █    █  █ ▀███▀  █   ▀▄ ▀███▀   
▀                     █    ▀             ▀             
                     ▀                   

█▀▄▀█ ▄███▄     ▄▄▄▄▀ ██   ██▄   ██     ▄▄▄▄▀ ██   
█ █ █ █▀   ▀ ▀▀▀ █    █ █  █  █  █ █ ▀▀▀ █    █ █  
█ ▄ █ ██▄▄       █    █▄▄█ █   █ █▄▄█    █    █▄▄█ 
█   █ █▄   ▄▀   █     █  █ █  █  █  █   █     █  █ 
   █  ▀███▀    ▀         █ ███▀     █  ▀         █ 
  ▀                     █          █            █  
                       ▀          ▀            ▀   
*/
contract DreamExeMetadata is Ownable
{
    using Strings for bytes;
    using Strings for uint256;
    string private baseImageURL;

    constructor() 
    {}

    function getBaseImageURL() external view returns(string memory) {
       return baseImageURL;
    }

    function setBaseImageURL(string calldata baseURL) external onlyOwner {
        baseImageURL = baseURL;
    }

    function getMetadataBytes(uint256 _tokenId, uint256 _inscriptionNum, string memory  _inscriptionId) public view returns (bytes memory) {
        bytes memory metadataBytes = abi.encodePacked(
                        '{"name":"dream.exe token # ',
                        _tokenId.toString(),
                        '","description":"What is DREAM.EXE?\\n\\nDREAM.EXE is a series of 3d generative artworks by Visual Swim, distributed as a novel implementation of durable blockchain storage and ownership.\\n\\nEach token is permanently preserved onto the Bitcoin blockchain, inscribed on individual satoshis as an Ordinal. Each piece of content is encoded with the OwnerName EXIF metadata, pointing to an ERC-721 contract address on the Ethereum blockchain. Ownership is trustlessly managed by this smart contract.\\n\\nThis is an entirely new way to store the assets that back non-fungible tokens on Ethereum.\\n\\nBy inscribing the asset that backs an NFT on the Bitcoin blockchain, certain guarantees are provided around durability and censorship resistance (as compared to IPFS or Arweave). Your asset will exist, in perpetuity, on the blockchain. It is not subject to governance or subjective limitations of the network participants.\\n\\nBy treating Inscriptions solely as a durable storage mechanism, Once an Ordinal has been Inscribed, we release the UTXO containing the Inscribed sat to Satoshi\'s wallet, where it will exist forever.\\n\\nDirect link to the Ordinal where this image is stored: ',
                        baseImageURL, '/', _inscriptionId, 
                        '","attributes":[{"trait_type":"Inscription #","value":"',
                        _inscriptionNum.toString(),
                        '"},{"trait_type":"InscriptionId","value":"',
                        _inscriptionId,
                        '"}], "image": "',
                        baseImageURL,
                        '/',
                        _inscriptionId,
                        '"}'
        );

        return metadataBytes;
    }
    
    function getMetadata(uint256 _tokenId, uint256 _ordinalId, string memory _inscriptionId) public view returns (string memory) {
        bytes memory metadata = getMetadataBytes( _tokenId, _ordinalId, _inscriptionId);
        
        return string(abi.encodePacked('data:application/json;base64,', Base64.encode(metadata)));
    }

}