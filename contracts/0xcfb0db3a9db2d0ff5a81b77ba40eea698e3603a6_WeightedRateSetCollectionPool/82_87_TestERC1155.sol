// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Test ERC1155 Token
 */
contract TestERC1155 is ERC1155, Ownable {
    /**************************************************************************/
    /* Constructor */
    /**************************************************************************/

    /**
     * @notice TestERC1155 constructor
     * @notice name Token name
     * @notice symbol Token symbol
     * @notice baseURI Token base URI
     */
    constructor(string memory uri) ERC1155(uri) {}

    /**************************************************************************/
    /* Privileged API */
    /**************************************************************************/

    /**
     * @notice Set token URI
     * @param uri Token URI
     */
    function setURI(string memory uri) external onlyOwner {
        _setURI(uri);
    }

    /**
     * @notice Mint tokens to account
     * @param to Recipient account
     * @param tokenId Token ID
     * @param amount Amount
     * @param data Data
     */
    function mint(address to, uint256 tokenId, uint256 amount, bytes memory data) external virtual onlyOwner {
        _mint(to, tokenId, amount, data);
    }

    /**
     * @notice Batch mint tokens to account
     * @param to Recipient account
     * @param tokenIds Token IDs
     * @param amounts Amounts
     * @param data Data
     */
    function mintBatch(
        address to,
        uint256[] memory tokenIds,
        uint256[] memory amounts,
        bytes memory data
    ) external virtual onlyOwner {
        _mintBatch(to, tokenIds, amounts, data);
    }

    /**
     * @notice Burn tokens
     * @param tokenId Token ID
     * @param amount Amount
     */
    function burn(uint256 tokenId, uint256 amount) external onlyOwner {
        _burn(msg.sender, tokenId, amount);
    }

    /**
     * @notice Batch burn tokens
     * @param tokenIds Token ID
     * @param amounts Amount
     */
    function burnBatch(uint256[] memory tokenIds, uint256[] memory amounts) external onlyOwner {
        _burnBatch(msg.sender, tokenIds, amounts);
    }
}