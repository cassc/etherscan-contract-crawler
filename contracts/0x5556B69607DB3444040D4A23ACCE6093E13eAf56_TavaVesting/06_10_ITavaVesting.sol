// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface ITavaVesting {
    /** 
        setVesting_ERR01 : The amount you are trying to pay is too small.
        setVesting_ERR02 : duration must be greater than zero.
        setVesting_ERR03 : unlockCnt must be greater than zero.

        cancelVesting_ERR01 : Cancellation is not possible after receiving the compensation.
        cancelVesting_ERR02 : Cancellable period has passed.

        claimVesting_ERR01 : This is a canceled vesting
        claimVesting_ERR02 : There is no quantity available yet.
        claimVesting_ERR03 : All tokens received.
        claimVesting_ERR04 : There is no balance available.
    */ 


    // [private] condition 정보 구조체
    struct VestingCondition {
        uint256 duration;
        uint256 unlockCnt;
        uint256 StartDt;
    }

    // [public] vesting 정보 구조체
    struct VestingInfo {
        VestingCondition vestingCondition;
        uint256 TotalAmount;
        uint256 tokensSent;
        bool valid;
    }

    // [onlyOwner] tava token 주소 변경
    function setTavaAddress(address _tavaTokenAddress) external;

    // [onlyOwner] vesting 등록
    function setVesting(address _receiver, uint256 _unlockedTokenAmount, uint256 _duration, uint256 _unlockCnt, uint256 _StartDt) external;

    // [onlyOwner] vesting 취소
    function cancelVesting(address _receiver, uint256 _vestingIdx) external;

    // [allUser] tava token 권한 이전
    function approvalTava(uint256 _amount) external;

    // [allUser] vesting 금액 수령
    function claimVesting(uint256 _vestingIdx) external returns(uint256 _TokenPayout);

    // [onlyOwner] contract 내부 타바 전부 회수
    function claimTava() external;

    // [onlyOwner] contract 내부 타바 일부 회수
    function claimTava(uint256 _amount) external;

    // [allUser] vesting 후 경과일 계산
    function getElapsedDays(address _receiver, uint256 _vestingIdx) external view returns(uint256 _elapsedDays);

    // [allUser] vesting 하나의 현재 받을 수 있는 토큰 량
    function TokensCurrentlyReceiveable(address _receiver, uint256 _vestingIdx) external view returns(uint256 _ReciveableTokens);

    // [allUser] vesting 현재까지 받아간 tava token 량
    function sentTavasToAdr(address _receiver, uint256 _vestingIdx) external view returns(uint256 _sentTavas);

    // Event
    event createdVesting(address _receiver, uint256 _vestingIdx, uint256 _unlockedTokenAmount, uint256 _duration, uint256 _unlockCnt, uint256 _StartDt);
    event canceledVesting(address _receiver, uint256 _vestingIdx);
    event claimedVesting(address _receiver,  uint256 _vestingIdx, uint256 _TokenPayout, uint256 _receivedDt);
}