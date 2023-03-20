// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.17;

interface IRewardDistributorDef {
    error ClaimPeriodNotStartOrEnd();
    error AmountExceedBalance();
    error InvalidProof();
    error AlreadyClaimed();
    error RootSetTwice();
    error ZeroRootSet();
    error InvalidTimestap();

    event Claim(address indexed claimant, uint256 amount);
    event MerkleRootChanged(bytes32 merkleRoot);
    event ClaimPeriodEndsChanged(uint256 claimPeriodEnds);
    event WithDrawn(address dest, uint256 amount);
}

interface IRewardDistributor is IRewardDistributorDef {}