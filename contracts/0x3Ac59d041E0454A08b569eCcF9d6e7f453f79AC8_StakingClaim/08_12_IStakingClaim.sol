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


    // [allUser] tava token 권한 이전
    function approvalTava(uint256 _amount) external;

    // [onlyOwner] contract 내부 타바 전부 회수
    function claimTava() external;

    // [onlyOwner] contract 내부 타바 일부 회수
    function claimTava(uint256 _amount) external;

    // [allUser] vesting 후 경과일 계산
    function GetElapsedToDuration(uint256 _roothashIdx) external view returns(uint256 _elapsedDays);

    // [allUser] 현재 까지 받을 수 있는 토큰량
    function GetTokensCurrentlyReciveable(uint256 _roothashIdx, uint256 _proofLength) external view returns(uint256 _tokensCurrentlyReciveable);

    // [allUser] 현재 까지 등록된 총 토큰 수량
    function GetTotalVestedTokenAmount() external view returns(uint256 _totalVestedTokenAmount);

    // [allUser] 현재 까지 락업 해제된 토큰 량
    function GetUnlockedAmount() external view returns(uint256 _unlockedAmount);

    function GetUnlockedAmount(uint256 _roothashIdx) external view returns(uint256 _unlockedAmount);

    // [owner] 머클트리 등록
    function SetRootHash(bytes32 _root, uint256 _paymentDt, uint256 _vestedTokenAmount) external;
    event setRootHash(uint256 _paymentDate, uint256 _roothashIdx);

    function SetRewardCA(address _rewardCA) external;
    event setRewardCA(address _rewardCA);

    // [owner] condition 변경
    function SetCondition(uint256 duration, uint256 unlockCnt) external;
    event setCondition (uint256 duration, uint256 unlockCnt);

    // [allUser] 스테이킹 보상 수령
    function ClaimToStaking(uint256 _roothashIdx, bytes32[] memory _proof, bool[] memory _proofFlags, bytes32[] memory _leaves) external;
    event claimToStaking(address _addressee, uint256 _roothashIdx, uint256 _amountReceived, uint256 _receivedDt);
}