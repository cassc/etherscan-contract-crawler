// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

interface ITavaStakingClaim {
    /**
        SetStakedInfo_ERR_001 : 데이터는 최대 40개 까지만 넣을 수 있습니다.
        Claim_ERR_001 : 더이상 받을 수 있는 토큰이 없습니다.
    */
    struct IStakedInfoInput {
        address _receiver;
        uint256 _totalReceiveableTokenAmount;
    }
    struct IStakedRecivedInfoInput {
        address _receiver;
        uint256 _totalReceiveableTokenAmount;
        IReceivedInfo _receivedInfo;
    }

    struct ICondition {
        uint256 _duration;
        uint256 _unlockCount;
    }

    struct IReceivedInfo {
        uint256 _receivedDate;
        uint256 _receivedTokenAmount;
    }
    event setStakedInfos(uint256 _receiveableDateIdx, uint256 _offsetNum);
    event setStakedInfo(address _receiver, uint256 _receiveableDateIdx, uint256 _totalReceiveableTokenAmount);
    event setCondition(ICondition _condition);
    event setReceiveableDates(uint256[] _receiveableDates);
    event stakingClaim(address _receiver, uint256 _receivedDate, uint256 _receivedTokenAmount, uint256 _receiveableDateIdx);
    function GetElapsedToDuration(uint256 _receiveableDateIdx) external view returns(uint256 _elapsedDays);
    function GetCurrentReceivedToken(address _receiver, uint256 _receiveableDateIdx) external view returns (uint256 _currentReceivedTokenAmount);
    function GetCurrentReceiveableToken(address _receiver, uint256 _receiveableDateIdx, uint256 _elapsedToDuration) external view returns (uint256 _currentReceiveableToken);
    function GetReceivedInfo(address _receiver, uint256 _receiveableDateIdx) external view returns (uint256 _receivedAmount);
    function SetStakedInfos(IStakedInfoInput[] calldata _stakedInfoInput, uint256 _receiveableDateIdx, uint256 _offsetNum) external;
    function SetStakedRecivedInfo(IStakedRecivedInfoInput[] calldata _stakedRecivedInfoInput, uint256 _receiveableDateIdx, uint256 _offsetNum) external;
    function SetStakedInfo(address _receiver, uint256 _receiveableDateIdx, uint256 _totalReceiveableTokenAmount) external;
    function SetCondition(uint256 _duration, uint256 _unlockCount) external;
    function SetReceiveableDates(uint256[] calldata _receiveableDates) external;
    function StakingClaim(uint256 _receiveableDateIdx) external;
}