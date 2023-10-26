// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

/*
    Interface for a Distributor of ERC20 tokens.
*/

// The DistributorTypeMerkleV# constants identify the Distributor type. These
// are used when emitting events.
uint256 constant DistributorTypeMerkleV1 = 1;
uint256 constant DistributorTypeMerkleV2 = 2;

// Allows anyone to claim a token if they haven't already.
interface IERC20Distributor {
    // Returns the address of the token distributed by this contract.
    function token() external view returns (address);

    function manifest() external view returns (string memory);

    // Returns true if the index has been marked claimed.
    function isClaimed(uint256 index) external view returns (bool);

    // Sets the token for the Distributor. Aborts if already done.
    function setToken(address token_) external;

    // This event is triggered whenever a call to #claim succeeds.
    event ERC20ClaimForAccount(uint256 index, uint256 amount, address account);

    // This event is triggered when the (first) call to #distribute succeeds.
    event ERC20Distribution(address token, uint256 distributorType);
}