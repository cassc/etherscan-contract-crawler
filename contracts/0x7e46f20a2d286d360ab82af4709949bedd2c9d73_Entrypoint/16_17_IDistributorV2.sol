// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

/*
    Interface for the DistributorV2. Adds two functions onto IERC20Distributor.
*/

import "./IERC20Distributor.sol";

interface IDistributorV2 is IERC20Distributor {
    // Returns the merkle root of the merkle tree containing account balances available to claim.
    function merkleRoot() external view returns (bytes32);

    // Claim the given amount of the token to the given address. Reverts if the inputs are invalid.
    function claimForAccount(
        uint256 index,
        uint256 amount,
        address account,
        bytes32[] calldata merkleProof
    ) external;
}