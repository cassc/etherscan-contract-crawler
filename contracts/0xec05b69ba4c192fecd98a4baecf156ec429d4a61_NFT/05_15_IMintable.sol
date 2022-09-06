// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// IMintable interface that's necessary for withdrawal of L2-minted tokens to L1
// Implemented in IMXMethods.sol
interface IMintable {
    function mintFor(address to, uint256 quantity, bytes calldata blueprint) external;
}