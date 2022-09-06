// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

/// @title TheyXoloHonorary
/// @author cesargdm.eth

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TheyXoloHonorary is ERC1155, ERC1155Burnable, Ownable {
    mapping(uint256 => bool) isMinted;

    constructor() ERC1155("https://theyxolo.art/api/honorary/{id}.json") {}

    /**
    * @notice Set base URI for the tokens
    * @param _baseURI New base token URI
    */
    function setBaseURI(string memory _baseURI) external onlyOwner {
        _setURI(_baseURI);
    }

    /**
    * @notice Mint a quantity of new tokens only callable by the contract owner
    * @param _tokenId Token ID to mint
    * @param _amount Number of editions of the token
    */
    function mint(uint256 _tokenId, uint256 _amount) external onlyOwner {
        /*
        We want to prevent minting the same token, this way we ensure no more editions are created
        for the same token id.
        */
        require(!isMinted[_tokenId], "TheyXoloHonorary: Token ID already exists");

        _mint(msg.sender, _tokenId, _amount, "");

        isMinted[_tokenId] = true;
    }
}