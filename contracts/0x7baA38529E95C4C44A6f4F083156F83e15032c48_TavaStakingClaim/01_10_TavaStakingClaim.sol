// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;


import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ITavaStakingClaim.sol";

contract TavaStakingClaim is ITavaStakingClaim, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    mapping(address => mapping(uint256 => IReceivedInfo[])) public ReceivedInfos;
    mapping(address => mapping(uint256 => uint256)) public StakedInfos;
    uint256 public TotalReceivedTokenAmount = 0;
    uint256[] public ReceiveableDates;
    ICondition public Condition;
    address public RewardTokenAddress;

    constructor (uint256[] memory _receiveableDates, address _rewardTokenAddress) {
        Condition = ICondition(30, 4);
        ReceiveableDates = _receiveableDates;
        RewardTokenAddress = _rewardTokenAddress;
    }

    // view function START
    function BalanceToAddress(address account) 
        external view returns(uint256)
    {
        return IERC20(RewardTokenAddress).balanceOf(account);
    }

    function GetElapsedToDuration(uint256 _receiveableDateIdx) 
        public view override
        returns(uint256 _elapsedDays)
    {
        uint256 _duration = (Condition._duration) * 1 days;
        uint256 _receiveableDate = ReceiveableDates[_receiveableDateIdx]; // 보상 받기 시작되는 날짜


        if(_receiveableDate > block.timestamp){
            return 0;
        }

        uint256 _elapsedDaysTemp = (block.timestamp.sub(_receiveableDate)).div(_duration) + 1;
        if(_elapsedDaysTemp > 4) {
            return 4;
        } else {
            return _elapsedDaysTemp;
        }
    }

    function GetCurrentReceivedToken(address _receiver, uint256 _receiveableDateIdx)
        public view override
        returns (uint256 _CurrentReceivedTokenAmount)
    {
        IReceivedInfo[] memory _ReceivedInfos = ReceivedInfos[_receiver][_receiveableDateIdx];
        uint256 _CurrentReceivedTokens = 0;
        for (uint256 i = 0; i < _ReceivedInfos.length; i++) {
            _CurrentReceivedTokens = _ReceivedInfos[i]._receivedTokenAmount;
        }
        return _CurrentReceivedTokens;
    }

    function GetCurrentReceiveableToken(address _receiver, uint256 _receiveableDateIdx, uint256 _elapsedToDuration)
        public view override
        returns (uint256 _currentReceiveableToken)
    {
        uint256 _totalReceiveableTokenAmount = StakedInfos[_receiver][_receiveableDateIdx];
        uint256 _unlockCount = Condition._unlockCount;
        uint256 _totalCurrentReceiveableTokenAmount = _totalReceiveableTokenAmount.div(_unlockCount).mul(_elapsedToDuration); // 현재 받을 수 있는 토큰량 : 단위 wei
        uint256 _currentReceivedTokenAmount = GetCurrentReceivedToken(_receiver, _receiveableDateIdx); // 받아간 토큰량 : 단위 wei
        if(_totalCurrentReceiveableTokenAmount > _currentReceivedTokenAmount) return _totalCurrentReceiveableTokenAmount.sub(_currentReceivedTokenAmount);
        else return 0;
    }

    function GetReceivedInfo(address _receiver, uint256 _receiveableDateIdx)
        public view override
        returns (uint256 _ReceivedAmount)
    {
        uint256 _receivedInfoLength = ReceivedInfos[_receiver][_receiveableDateIdx].length;
        uint256 _receivedAmount = 0;
        for (uint256 i = 0; i < _receivedInfoLength; i++) {
            _receivedAmount += ReceivedInfos[_receiver][_receiveableDateIdx][i]._receivedTokenAmount;
        }
        return _receivedAmount;
    }

    // view function END

    function SetRewardTokenAddress(address _rewardTokenAddress) 
        external onlyOwner 
    {
        RewardTokenAddress = _rewardTokenAddress;
    }


    function SetStakedInfos(IStakedInfoInput[] calldata _stakedInfoInput, uint256 _receiveableDateIdx, uint256 _offsetNum)
        external onlyOwner override
    {
        require(_stakedInfoInput.length < 41,"setStakedInfo_ERR_001");

        for (uint256 i = 0; i < _stakedInfoInput.length; i++) {
            address _receiver = _stakedInfoInput[i]._receiver;
            uint256 _totalReceiveableTokenAmount = _stakedInfoInput[i]._totalReceiveableTokenAmount * 1 ether;
            StakedInfos[_receiver][_receiveableDateIdx] = _totalReceiveableTokenAmount;
        }
        emit setStakedInfos(_receiveableDateIdx, _offsetNum);
    }

    function SetStakedRecivedInfo(IStakedRecivedInfoInput[] calldata _stakedRecivedInfoInput, uint256 _receiveableDateIdx, uint256 _offsetNum)
        external onlyOwner override
    {
        require(_stakedRecivedInfoInput.length < 41,"setStakedInfo_ERR_001");

        for (uint256 i = 0; i < _stakedRecivedInfoInput.length; i++) {
            address _receiver = _stakedRecivedInfoInput[i]._receiver;
            uint256 _totalReceiveableTokenAmount = _stakedRecivedInfoInput[i]._totalReceiveableTokenAmount * 1 ether;
            StakedInfos[_receiver][_receiveableDateIdx] = _totalReceiveableTokenAmount;
            if(_stakedRecivedInfoInput[i]._receivedTokenAmount > 0) {
                ReceivedInfos[_receiver][_receiveableDateIdx].push(IReceivedInfo(_stakedRecivedInfoInput[i]._receivedDate, _stakedRecivedInfoInput[i]._receivedTokenAmount));
                TotalReceivedTokenAmount += _stakedRecivedInfoInput[i]._receivedTokenAmount;
            }
        }
        emit setStakedInfos(_receiveableDateIdx, _offsetNum);
    }

    function SetStakedInfo(address _receiver, uint256 _receiveableDateIdx, uint256 _totalReceiveableTokenAmount) 
        external onlyOwner override
    {
        StakedInfos[_receiver][_receiveableDateIdx] = _totalReceiveableTokenAmount;
        emit setStakedInfo(_receiver, _receiveableDateIdx, _totalReceiveableTokenAmount);
    }

    function SetCondition(uint256 _duration, uint256 _unlockCount)
        external onlyOwner override
    {
        Condition = ICondition(_duration, _unlockCount);
        emit setCondition(ICondition(_duration, _unlockCount));
    }

    function SetReceiveableDates(uint256[] calldata _receiveableDates) 
        external onlyOwner override
    {
        ReceiveableDates = _receiveableDates;
        emit setReceiveableDates(_receiveableDates);
    }

    function StakingClaim(uint256 _receiveableDateIdx) 
        external nonReentrant override
    {
        uint256 _elapsedToDuration = GetElapsedToDuration(_receiveableDateIdx);
        uint256 _currentReceiveableToken = GetCurrentReceiveableToken(_msgSender(), _receiveableDateIdx, _elapsedToDuration);
        require(_currentReceiveableToken > 0, "Claim_ERR_001");

        IERC20(RewardTokenAddress).transfer(_msgSender(), _currentReceiveableToken);
        ReceivedInfos[_msgSender()][_receiveableDateIdx].push(IReceivedInfo(block.timestamp, _currentReceiveableToken));
        TotalReceivedTokenAmount += _currentReceiveableToken;
        emit stakingClaim(_msgSender(), block.timestamp, _currentReceiveableToken, _receiveableDateIdx);
    }

    function claimTava() 
        external    
        onlyOwner
    {
        uint256 _TavaBalance = IERC20(RewardTokenAddress).balanceOf(address(this));
        IERC20(RewardTokenAddress).transfer(owner(), _TavaBalance);
    }

    function claimTava(uint256 _amount) 
        external  
        onlyOwner
    {
        IERC20(RewardTokenAddress).transfer(owner(), _amount.mul(1 ether));
    }
}