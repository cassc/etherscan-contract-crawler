// SPDX-License-Identifier: MIT

/**
*   @title Never Fear Truth
*   @author Transient Labs
*   @notice ERC 1155 contract, single token, single owner, optimized for airdrops 
*/

/**
   ___                            __  ___         ______                  _          __    __        __     
  / _ \___ _    _____ _______ ___/ / / _ )__ __  /_  __/______ ____  ___ (_)__ ___  / /_  / /  ___ _/ /  ___
 / ___/ _ \ |/|/ / -_) __/ -_) _  / / _  / // /   / / / __/ _ `/ _ \(_-</ / -_) _ \/ __/ / /__/ _ `/ _ \(_-<
/_/   \___/__,__/\__/_/  \__/\_,_/ /____/\_, /   /_/ /_/  \_,_/_//_/___/_/\__/_//_/\__/ /____/\_,_/_.__/___/
                                        /___/                                                               
*/

pragma solidity ^0.8.0;

import "ERC1155.sol";
import "Ownable.sol";
import "Strings.sol";
import "EIP2981.sol";

contract NeverFearTruth is ERC1155, EIP2981, Ownable {
    using Strings for uint256;

    uint256 internal availableTokenSupply;
    uint256 public tokenSupply;

    string public name;

    constructor(string memory _name, uint256 _tokenSupply, address _royaltyRecipient, uint256 _royaltyAmount) EIP2981(_royaltyRecipient, _royaltyAmount) ERC1155("") Ownable() {
        name = _name;
        tokenSupply = _tokenSupply;
        availableTokenSupply = _tokenSupply;
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
    *   @notice function to return totalSupply
    *   @return uint256 value of supply
    */
    function totalSupply() public view returns(uint256) {
        return tokenSupply;
    }

    /**
    *   @notice sets the baseURI for the tokens
    *   @dev requires owner
    *   @dev emits URI event per the ERC 1155 standard
    *   @param _uri is the base URI set for each token
    */
    function setBaseURI(string memory _uri) public onlyOwner {
        _setURI(_uri);
        emit URI(_uri, 0);
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
        require(_tokenId == 0, "Error: non-existent token id");
        return string(abi.encodePacked(ERC1155.uri(_tokenId), _tokenId.toString()));
    }

    /**
    *   @notice function for batch minting the token to many addresses
    *   @dev requires owner
    *   @param _addresses is an array of addresses to mint to
    */
    function batchMintToAddresses(address[] calldata _addresses) public onlyOwner {
        require(availableTokenSupply >= _addresses.length, "Error: not enough token supply available");
        
        for (uint256 i = 0; i < _addresses.length; i++) {
            _mint(_addresses[i], 0, 1, "");
        }

        availableTokenSupply -= _addresses.length;
    }
}