// SPDX-License-Identifier: MIT
pragma solidity =0.8.7;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface IChad is IERC721 {
    /**
     * @notice Mints specified number of tokens in a single transaction
     * @param amount Total number of tokens to be minted and sent to `_msgSender()`
     *
     * Requirements:
     *
     * - `amount` must be less than max limit for a single transaction
     * - `block.timestamp` must be greater than the sale start timestamp
     * - `msg.value` must be exact (or greater) payment amount in wei
     * - `currentPublicAmount` plus amount must not exceed max public amount
     */
    function mint(uint256 amount) external payable;

    /**
     * @notice Mints specified number of tokens to every recipient in a single transaction
     * @param amount Total number of tokens to be minted and sent to every recipient
     * @param recipients Array of tokens recepients
     *
     * Requirements:
     *
     * - can be called by the owner
     * - `currentReservedAmount` plus amount per recipient must not exceed the max reserved amount
     */
    function mintReserved(uint256 amount, address[] calldata recipients) external;

    /**
     * @notice Transfers Ether to the contract owner
     *
     * Requirements:
     *
     * - can be called by the owner
     */
    function withdrawEther() external;

    /**
     * @notice Set new prefix of each tokenURI
     *
     * Requirements:
     *
     * - can be called by the owner
     */
    function setBaseURI(string memory newBaseURI) external;

    /**
     * @notice Set new collection metadata URI
     *
     * Requirements:
     *
     * - can be called by the owner
     */
    function setContractURI(string memory newContractURI) external;

    /**
     * @notice Collection metadata URI
     */
    function contractURI() external view returns (string memory);

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);
}