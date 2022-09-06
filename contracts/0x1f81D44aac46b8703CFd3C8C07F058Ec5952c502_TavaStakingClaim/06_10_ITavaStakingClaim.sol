// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

interface ITavaStakingClaim {
    /**
        SetStakedInfo_ERR_001 : 데이터는 최대 40개 까지만 넣을 수 있습니다.
        Claim_ERR_001 : 더이상 받을 수 있는 토큰이 없습니다.
    */
    struct IStakedInfoInput {
        address _receiver;
        uint256 _TotalReceiveableTokenAmount;
    }

    struct ICondition {
        uint256 _duration;
        uint256 _unlockCount;
    }

    struct IReceivedInfo {
        uint256 _ReceivedDate;
        uint256 _ReceivedTokenAmount;
    }
    event setStakedInfos(uint256 _ReceiveableDateIdx, uint256 _OffsetNum);
    event setStakedInfo(address _receiver, uint256 _ReceiveableDateIdx, uint256 _TotalReceiveableTokenAmount);
    event setCondition(ICondition _condition);
    event setReceiveableDates(uint256[] _ReceiveableDates);
    event stakingClaim(address _receiver, uint256 _ReceivedDate, uint256 _ReceivedTokenAmount, uint256 _ReceiveableDateIdx);
    function GetElapsedToDuration(uint256 _ReceiveableDateIdx) external view returns(uint256 _elapsedDays);
    function GetCurrentReceivedToken(address _receiver, uint256 _ReceiveableDateIdx) external view returns (uint256 _CurrentReceivedTokenAmount);
    function GetCurrentReceiveableToken(address _receiver, uint256 _ReceiveableDateIdx, uint256 _ElapsedToDuration) external view returns (uint256 _CurrentReceiveableToken);
    function GetReceivedInfo(address _receiver, uint256 _ReceiveableDateIdx) external view returns (uint256 _ReceivedAmount);
    function SetStakedInfos(IStakedInfoInput[] calldata _StakedInfoInput, uint256 _ReceiveableDateIdx, uint256 _OffsetNum) external;
    function SetStakedInfo(address _receiver, uint256 _ReceiveableDateIdx, uint256 _TotalReceiveableTokenAmount) external;
    function SetCondition(uint256 _duration, uint256 _unlockCount) external;
    function SetReceiveableDates(uint256[] calldata _ReceiveableDates) external;
    function StakingClaim(uint256 _ReceiveableDateIdx) external;
}