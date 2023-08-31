// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "../dependencies/openzeppelin/IERC20.sol";

interface IBMerkleOrchard {
    struct Claim {
        uint256 distributionId;
        uint256 balance;
        address distributor;
        uint256 tokenIndex;
        bytes32[] merkleProof;
    }

    function claimDistributions(
        address claimer,
        Claim[] memory claims,
        IERC20[] memory tokens
    ) external;
}