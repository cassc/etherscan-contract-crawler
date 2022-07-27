// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract HouseOfFud is ERC1155, Ownable {

    string private contractMetadataURI;
    mapping(uint256 => string) public collabURI;


    constructor() ERC1155("") {
    }

    function airdrop(address to, uint256 typeId, uint256 amount) 
        external
        onlyOwner 
    {
        _mint(to, typeId, amount, "");
    }

    function airdropMultiAddress(address[] memory receivers, uint256 typeId, uint256 amount) 
        external 
        onlyOwner 
    {
        for (uint256 i = 0; i < receivers.length; i++) {
            _mint(receivers[i], typeId, amount, "");
        }
    }


    function setContractURI(string memory _uri) external onlyOwner {
        contractMetadataURI = _uri;
    }
    
    function contractURI() 
        public 
        view 
        returns (string memory)
    {
        return contractMetadataURI;
    }

    function setCollabURI(uint256 typeId, string memory _uri) 
        external
        onlyOwner 
    {
        collabURI[typeId] = _uri;
    }


    function uri(uint256 typeId)
        public
        view                
        override
        returns (string memory){
        return collabURI[typeId];
    }
}