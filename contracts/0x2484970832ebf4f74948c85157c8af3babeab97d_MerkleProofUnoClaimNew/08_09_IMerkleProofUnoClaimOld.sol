// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

// Allows anyone to claim a token if they exist in a merkle root.
interface IMerkleProofUnoClaimOld {
    struct UserInfo {
        uint128 claimedAmount;
        uint128 lastClaimTime;
    }

    function userInfo(address _account) external view returns (UserInfo memory);

    // Claim the given amount of the token to the given address. Reverts if the inputs are invalid.
    function airdropUNO(
        uint128 _index,
        address _account,
        uint128 _amount,
        bytes32[] calldata _merkleProof
    ) external;

    // This event is triggered whenever a call to #claim succeeds.
    event LogAirdropUNO(uint128 _index, address _account, uint128 _totalClaimAmount, uint128 _claimAmount);
    event LogSetMerkleRoot(address indexed _contract, bytes32 _merkleRoot);
    event LogEmergencyWithdraw(address indexed _from, address indexed _currency, address _to, uint256 _amount);
}