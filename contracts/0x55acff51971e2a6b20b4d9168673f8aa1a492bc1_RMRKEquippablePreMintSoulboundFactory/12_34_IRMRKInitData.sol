// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.18;

/**
 * @title IRMRKInitData
 * @author RMRK team
 * @notice Interface representation of RMRK initialization data.
 * @dev This interface provides a struct used to pack data to avoid stack too deep error for too many arguments.
 */
interface IRMRKInitData {
    /**
     * @notice Used to provide initialization data without running into stack too deep errors.
     * @return erc20TokenAddress Address of the ERC20 token to be used when initializing a smart contract that supports
     *  ERC20 pay module
     * @return tokenUriIsEnumerable Weather the token URI is enumerable or not
     * @return royaltyRecipient Recipient of resale royalties
     * @return royaltyPercentageBps The percentage to be paid from the sale of the token expressed in basis points
     * @return maxSupply The maximum supply of tokens
     * @return pricePerMint The price per single-token mint expressed in the lowest denomination of native currency
     */
    struct InitData {
        address erc20TokenAddress; // 20 bytes
        bool tokenUriIsEnumerable; // 1 byte
        // --- new slot ---
        address royaltyRecipient; // 20 bytes
        uint16 royaltyPercentageBps; // 2 bytes
        // --- new slot ---
        uint256 maxSupply;
        // --- new slot ---
        uint256 pricePerMint;
        // another 32 bytes
    }
}