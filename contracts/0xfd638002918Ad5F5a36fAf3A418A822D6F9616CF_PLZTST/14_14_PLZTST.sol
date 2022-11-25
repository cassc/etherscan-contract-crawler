// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

contract PLZTST is ERC721URIStorage {
    using Strings for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    
    address private admin = 0x88e187E926C52C8E47Ca6e6a71D5D7ceB739c07D;

    mapping(uint256 => uint256) public tokenIdToDelivery;
    mapping(uint256 => string) public tokenIdToIPFSImageLink;


    constructor() ERC721("Pillz Test Token Name", "PLZTST"){

    }

    function isPersonWaitingForDelivery(uint256 tokenId) public view returns (string memory){
        uint256 status = tokenIdToDelivery[tokenId];
        return status.toString();
    }

    function getTokenURI(uint256 tokenId) public returns (string memory){
        bytes memory dataURI = abi.encodePacked(
            '{',
                '"name": "Pillz test token KEK #', tokenId.toString(), '",',
                '"description": "HOHO we are testing pillz token",',
                '"image": "', tokenIdToIPFSImageLink[tokenId] ,'",',
            '}'
        );

        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(dataURI)
            )
        );
    }

    function mint() public {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _safeMint(msg.sender, newItemId);
        tokenIdToDelivery[newItemId] = 0;
        tokenIdToIPFSImageLink[newItemId] = 'ipfs://QmUBc7GDUBzRpTZvvAyunoCWT33HMLRcKAyhRbv6nwqdcF';
        _setTokenURI(newItemId, getTokenURI(newItemId));
    }

    function promoteCharacter(uint256 tokenId, string memory ipfslink) public {
        require(_exists(tokenId), "Please use a token that exists.");
        require(msg.sender == admin, "Only PILLZ inc staff can change this data.");
        tokenIdToIPFSImageLink[tokenId] = ipfslink;
        _setTokenURI(tokenId, getTokenURI(tokenId));
    }   
    
    function setWaitingForDeliveryStatus(uint256 tokenId, uint256 status) public {
        require(_exists(tokenId), "Please use a token that exists.");
        require(msg.sender == admin, "Only PILLZ inc staff can change this data.");
        tokenIdToDelivery[tokenId] = status;
        _setTokenURI(tokenId, getTokenURI(tokenId));
    }
}