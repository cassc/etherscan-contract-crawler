// SPDX-License-Identifier: MIT

/**
*   @title TIMEPieces x FOTO
*   @author Transient Labs, Copyright (C) 2021
*   @notice ERC 1155 contract, single owner, optimized for airdrops 
*   @dev includes the public parameter `name` so it works with OS
*/

/*
 #######                                                      #                            
    #    #####    ##   #    #  ####  # ###### #    # #####    #         ##   #####   ####  
    #    #    #  #  #  ##   # #      # #      ##   #   #      #        #  #  #    # #      
    #    #    # #    # # #  #  ####  # #####  # #  #   #      #       #    # #####   ####  
    #    #####  ###### #  # #      # # #      #  # #   #      #       ###### #    #      # 
    #    #   #  #    # #   ## #    # # #      #   ##   #      #       #    # #    # #    # 
    #    #    # #    # #    #  ####  # ###### #    #   #      ####### #    # #####   #### 
    
0101010011100101100000110111011100101101000110010011011101110100 01001100110000011000101110011 
*/

pragma solidity ^0.8.0;

import "ERC1155.sol";
import "Ownable.sol";
import "Strings.sol";
import "EIP2981.sol";

contract TIMEPiecesFOTO is ERC1155, EIP2981, Ownable {
    using Strings for uint256;

    uint256 constant FOTO_BOOK_ONE = 0;
    uint256 constant FOTO_BOOK_TWO = 1;

    uint256[2] internal availableTokenSupply;
    mapping(uint256 => uint256) public tokenSupply;

    string public name;

    constructor(string memory _name, uint256 _tokenOneSupply, uint256 _tokenTwoSupply, address _royaltyRecipient, uint256 _royaltyAmount) EIP2981(_royaltyRecipient, _royaltyAmount) ERC1155("") Ownable() {
        name = _name;
        tokenSupply[FOTO_BOOK_ONE] = _tokenOneSupply;
        tokenSupply[FOTO_BOOK_TWO] = _tokenTwoSupply;
        availableTokenSupply[FOTO_BOOK_ONE] = _tokenOneSupply;
        availableTokenSupply[FOTO_BOOK_TWO] = _tokenTwoSupply;
    }

    /**
    *   @notice overrides supportsInterface function
    *   @param _interfaceId is supplied from anyone/contract calling this function, as defined in ERC 165
    *   @return a boolean saying if this contract supports the interface or not
    */
    function supportsInterface(bytes4 _interfaceId) public view virtual override(ERC1155, EIP2981) returns (bool) {
        return super.supportsInterface(_interfaceId);
    }

    /**
    *   @notice function to return totalSupply of a token ID
    *   @param _tokenId is the uint256 identifier of a tokenId
    *   @return uint256 value of supply
    */
    function totalSupply(uint256 _tokenId) public view returns(uint256) {
        return tokenSupply[_tokenId];
    }

    /**
    *   @notice sets the baseURI for the tokens
    *   @dev requires owner
    *   @param _uri is the base URI set for each token
    */
    function setBaseURI(string memory _uri) public onlyOwner {
        _setURI(_uri);
    }

    /**
    *   @notice function to change the royalty recipient
    *   @dev requires owner
    *   @dev this is useful if an account gets compromised or anything like that
    *   @param _newRecipient is the new royalty recipient
    */
    function changeRoyaltyRecipient(address _newRecipient) public onlyOwner {
        require(_newRecipient != address(0), "Error: new recipient is the zero address");
        royaltyAddr = _newRecipient;
    }

    /**
    *   @notice function to change the royalty percentage
    *   @dev requires owner
    *   @dev this is useful if the amount was set improperly at contract creation. This can in fact happen... humans are prone to mistakes :) 
    *   @param _newPerc is the new royalty percentage, in basis points (out of 10,000)
    */
    function changeRoyaltyPercentage(uint256 _newPerc) public onlyOwner {
        require(_newPerc <= 10000, "Error: new percentage is greater than 10,0000");
        royaltyPerc = _newPerc;
    }

    /**
    *   @notice function to return uri for a specific token type
    *   @param _tokenId is the uint256 representation of a token ID
    *   @return string representing the uri for the token id
    */
    function uri(uint256 _tokenId) public view virtual override returns (string memory) {
        require(tokenSupply[_tokenId] > 0, "Error: non-existent token id");
        return string(abi.encodePacked(ERC1155.uri(_tokenId), _tokenId.toString()));
    }

    /**
    *   @notice function for batch minting a specific token id to many addresses
    *   @dev requires owner
    *   @param _tokenId is the token id
    *   @param _addresses is an array of addresses to mint to
    */
    function batchMintToAddresses(uint256 _tokenId, address[] calldata _addresses) public onlyOwner {
        require(_addresses.length > 0, "Error: empty address array passed to function");
        require(tokenSupply[_tokenId] > 0, "Error: non-existent token id");
        require(availableTokenSupply[_tokenId] >= _addresses.length, "Error: not enough token supply available");
        
        for (uint256 i = 0; i < _addresses.length; i++) {
            _mint(_addresses[i], _tokenId, 1, "");
        }

        availableTokenSupply[_tokenId] -= _addresses.length;
    }
}