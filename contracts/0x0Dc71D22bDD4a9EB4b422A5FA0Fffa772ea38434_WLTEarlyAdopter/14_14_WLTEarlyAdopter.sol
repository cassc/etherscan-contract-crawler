// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol";
import "./Shareholders.sol";
import "./LockURI.sol";

/**
 * @title WLTEarlyAdopter
 *
 *
 *   __      __.____  ___________
 *  /  \    /  \    | \__    ___/
 *  \   \/\/   /    |   |    |
 *   \        /|    |___|    |
 *    \__/\  / |_______ \____|
 *         \/          \/
 *
 * WLTEarlyAdopter - ERC-1155 smart contract for Satoshi's Closet WLT Early Adopter NFT
 */
contract WLTEarlyAdopter is ERC1155, ERC1155Holder, Shareholders, LockURI {

    // Contract name
    string public name = "$STCL WLT Early Adopter";
    // Contract symbol
    string public symbol = "STCLWLT";

    // Set prices for items that can be minted
    uint256[] private _itemPrices = [4200000000000000];
    // Set supplies for items that can be minted
    uint256[] private _itemSupplies = [1000];


    /**
     * @dev Constructor
     * @param _shares The number of shares each shareholder has
     * @param _shareholder_addresses Payment address for each shareholder
     */
    constructor(
        uint256[] memory _shares,
        address payable[] memory _shareholder_addresses
    ) ERC1155("") Shareholders(_shares, _shareholder_addresses){
    }

    /**
     * @dev See https://forum.openzeppelin.com/t/derived-contract-must-override-function-supportsinterface/6315
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, ERC1155Receiver) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns the max total supply of all tokens
     */
    function totalSupply() public view returns (uint256) {
        uint256 supply = 0;
        for(uint8 i=0; i < _itemSupplies.length; i++){
            supply += _itemSupplies[i];
        }
        return supply;
    }

    /**
     * @dev Returns the item prices array
     */
    function itemPrices() public view returns (uint256[] memory) {
        return _itemPrices;
    }

    /**
     * @dev Returns the item supplies array
     */
    function itemSupplies() public view returns (uint256[] memory) {
        return _itemSupplies;
    }

    /**
     * @dev For owner to set the base metadata URI while isUriLocked is false
     * @param _uri string - new value for metadata URI
     */
    function setURI(string memory _uri) public onlyOwner {
        require(isUriLocked == false, "URI is locked. Cannot set the base URI");
        _setURI(_uri);
    }

    /**
     * @dev Mint items
     * @param amount The number of items to mint.
     */
    function mint(address _to, uint256 tokenId, uint256 amount) public payable {
        require(tokenId > 0 && tokenId <= _itemPrices.length, "Token not available for minting");
        require(msg.value == _itemPrices[tokenId - 1] * amount, "Wrong minting fee"); // Starting from token ID 1
        require(amount <= _itemSupplies[tokenId - 1], "Not enough supply of this token"); // Starting from token ID 1
        _mint(_to, tokenId, amount, "");
        _itemSupplies[tokenId - 1] -= amount;
    }

    /**
     * @dev Mint items by Owner
     * @param amount The number of items to mint.
     */
    function ownerMint(address _to, uint256 tokenId, uint256 amount) public onlyOwner {
        require(tokenId > 0 && tokenId <= _itemPrices.length, "Token not available for minting");
        require(amount <= _itemSupplies[tokenId - 1], "Not enough supply of this token"); // Starting from token ID 1
        _mint(_to, tokenId, amount, "");
        _itemSupplies[tokenId - 1] -= amount;
    }

}