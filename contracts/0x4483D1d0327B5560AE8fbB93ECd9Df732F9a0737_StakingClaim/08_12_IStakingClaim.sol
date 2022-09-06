// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

/** 
    ClaimToStaking_ERR01 : Invalid MerkleTree data
    ClaimToStaking_ERR02 : You have received all your rewards.
    ClaimToStaking_ERR03 : There is no amount of TAVA reciveable.
*/ 

interface IStakingClaim {
    struct merkleTreeInfo {
        bytes32 rootHash;
        uint256 paymentDt;
        uint256 totalTokenAmount;
    }

    struct receivedInfo {
        uint256 roothashIdx;
        uint256 amountReceived;
    }

    struct stakingCondition {
        uint256 duration;
        uint256 unlockCnt;
    }

    function approvalTava(uint256 _amount) external;
    function claimTava() external;
    function claimTava(uint256 _amount) external;
    function GetElapsedToDuration(uint256 _roothashIdx) external view returns(uint256 _elapsedDays);
    function GetTokensCurrentlyReciveable(uint256 _roothashIdx, uint256 _proofLength) external view returns(uint256 _tokensCurrentlyReciveable);
    function GetTotalVestedTokenAmount() external view returns(uint256 _totalVestedTokenAmount);
    function GetUnlockedAmount() external view returns(uint256 _unlockedAmount);
    function GetUnlockedAmount(uint256 _roothashIdx) external view returns(uint256 _unlockedAmount);
    function SetRootHash(bytes32 _root, uint256 _paymentDt, uint256 _vestedTokenAmount) external;
    event setRootHash(uint256 _paymentDate, uint256 _roothashIdx);
    function SetRewardCA(address _rewardCA) external;
    event setRewardCA(address _rewardCA);
    function SetCondition(uint256 duration, uint256 unlockCnt) external;
    event setCondition (uint256 duration, uint256 unlockCnt);
    function ClaimToStaking(uint256 _roothashIdx, bytes32[] memory _proof, bool[] memory _proofFlags, bytes32[] memory _leaves) external;
    event claimToStaking(address _addressee, uint256 _roothashIdx, uint256 _amountReceived, uint256 _receivedDt);
}