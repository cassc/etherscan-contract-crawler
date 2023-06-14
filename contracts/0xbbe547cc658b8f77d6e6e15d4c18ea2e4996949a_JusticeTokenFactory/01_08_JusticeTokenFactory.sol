// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Ownable} from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {JusticeToken} from "./JusticeToken.sol";

/// @title JusticeTokenFactory
/// @author opnxj
/// @notice Factory for creating Justice Tokens
contract JusticeTokenFactory is Ownable {
    address[] public tokens;

    event TokenCreated(address indexed tokenAddress, string symbol);

    /// @notice Retrieves the number of created Justice Tokens
    /// @return The number of created tokens
    function numTokens() external view returns (uint256) {
        return tokens.length;
    }

    /// @notice Creates a new Justice Token contract with the specified symbol
    /// @param symbol The symbol of the Justice Token
    /// @param merkleRoot The Merkle root for airdrop claims
    /// @return The address of the newly created Justice Token contract
    function create(
        string memory symbol,
        bytes32 merkleRoot
    ) external onlyOwner returns (address) {
        JusticeToken newToken = new JusticeToken(
            symbol,
            merkleRoot,
            block.timestamp + 30 days // 1 month
        );
        tokens.push(address(newToken));
        emit TokenCreated(address(newToken), symbol);
        return address(newToken);
    }
}