// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
import './interfaces/IMerkleDistributor.sol';

contract MerkleDistributorAdaptor {
    function multiClaim(
        address account,
        address[] calldata distributors,
        uint256[] calldata indices,
        uint256[] calldata amounts,
        bytes32[][] calldata merkleProofs
    ) external {
        require(distributors.length > 0, 'Invalid length.');
        for (uint256 i; i < distributors.length; ++i) {
            IMerkleDistributor(distributors[i]).claim(indices[i], account, amounts[i], merkleProofs[i]);
        }
    }
}