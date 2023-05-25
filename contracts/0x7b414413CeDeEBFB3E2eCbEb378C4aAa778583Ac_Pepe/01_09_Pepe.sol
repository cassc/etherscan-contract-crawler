// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0; 

import "./Pepeable.sol";
import "./ERC721A.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

/*
* @title Strings
*/
contract Pepe is ERC721A, Pepeable, DefaultOperatorFilterer {

    string public BASE_URI;

    function pepe(address[] calldata _wallets, uint256[] calldata _quantities) external onlyPepe {
        
        if(_wallets.length != _quantities.length){
            revert("Unequal dataset sizes");
        }

        for (uint256 i = 0; i < _wallets.length; i++) {
            _mint(_wallets[i], _quantities[i]);
        }
    }

    /**
    * @notice sets the URI of where metadata will be hosted, gets appended with the token id
    *
    * @param _uri the amount URI address
    */
    function setBaseURI(string memory _uri) external onlyPepe {
        BASE_URI = _uri;
    }
    
    /**
    * @notice returns the URI that is used for the metadata
    */
    function _baseURI() internal view override returns (string memory) {
        return BASE_URI;
    }
    
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId), '.json')) : '';
    }

    /**
    * @notice Start token IDs from this number
    */
    function _startTokenId() internal override view virtual returns (uint256) {
        return 1;
    }

     function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        payable
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    constructor() ERC721A("Pepe", "PEPE") {
        BASE_URI = "ipfs://bafybeifngnsoz46dzrrd4qmiwe75sy4avlmyi5hjct3fb5rsy4xekd7gai/";
    }

}