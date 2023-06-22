// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IAngleMerkleDistributor {
    function claim(
        address[] calldata users, 
        address[] calldata tokens, 
        uint256[] calldata amounts, 
        bytes32[][] calldata proofs
    ) external;
    function toggleOperator(address user, address opperator) external;
    function toggleOnlyOperatorCanClaim(address user) external;
}