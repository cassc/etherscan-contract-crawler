// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.9;
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ITavaVesting.sol";

contract TavaVesting is ITavaVesting, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    address public tavaTokenAddress;
    uint256 public TotalTokensReceived = 0;
    uint256 public TotalTokensReceiveable = 0;
    uint256 constant tavaDecimal = 10 ** 18;
    
    mapping (address => VestingInfo[]) public vestingInfoToWallets;

    constructor(
        address _tavaTokenAddress
    ) {
        tavaTokenAddress = _tavaTokenAddress;
    }

    modifier notZeroAddress(address caller) {
        require(caller != address(0), "Cannot perform call function for address(0).");
        _;
    }

    function BalanceToAddress(address account) 
        external view returns(uint256)
    {
        return IERC20(tavaTokenAddress).balanceOf(account);
    }
    
    function TokensCurrentlyReceiveable(address _receiver, uint256 _vestingIdx) 
        public view override returns(uint256 _ReciveableTokens)
    {
        VestingCondition memory _vestingCondition = vestingInfoToWallets[_receiver][_vestingIdx].vestingCondition;
        uint256 _elapsedDays = getElapsedDays(_receiver, _vestingIdx);
        uint256 _totalAmount = vestingInfoToWallets[_receiver][_vestingIdx].totalAmount;
        if(_elapsedDays > _vestingCondition.unlockCnt){
            _elapsedDays = _vestingCondition.unlockCnt;
        }

        if(_elapsedDays == 0) {
            return 0;
        }

        uint256 _tokensPerStage = _totalAmount*(tavaDecimal)/(_vestingCondition.unlockCnt);
        uint256 receiveableTava = _tokensPerStage*(_elapsedDays);
        uint256 receivedTava = sentTavasToAdr(_receiver, _vestingIdx)*(tavaDecimal);

        if(receiveableTava < receivedTava){
            return 0;
        } else {
            return _ReciveableTokens = receiveableTava - receivedTava;
        }
    }

    function getElapsedDays(address _receiver, uint256 _vestingIdx) 
        public view override returns(uint256 _elapsedDays)
    {
        VestingCondition memory _vestingCondition = vestingInfoToWallets[_receiver][_vestingIdx].vestingCondition;
        uint256 _duration = _vestingCondition.duration;
        if(block.timestamp > _vestingCondition.startDt) {
            return (block.timestamp - _vestingCondition.startDt)/(_duration * 1 days);
        } else {
            return 0;
        }
    }
    
    function sentTavasToAdr(address _receiver, uint256 _vestingIdx) 
        public view override returns(uint256 _sentTavas)
    {
        return _sentTavas = vestingInfoToWallets[_receiver][_vestingIdx].tokensSent;
    }

    function setTavaAddress(address _tavaTokenAddress) 
        external onlyOwner
    {
        tavaTokenAddress = _tavaTokenAddress;
    }

    function setVesting(
        address _receiver, 
        uint256 _unlockedTokenAmount, 
        uint256 _duration,
        uint256 _unlockCnt,
        uint256 _startDt
    ) 
        external override onlyOwner notZeroAddress(_receiver)
    {
        require(_unlockedTokenAmount > 0, "setVesting_ERR01");
        require(_duration > 0, "setVesting_ERR02");
        require(_unlockCnt > 0, "setVesting_ERR03");
        VestingCondition memory _vestingCondition = VestingCondition(_duration, _unlockCnt, _startDt);
        vestingInfoToWallets[_receiver].push(VestingInfo(_vestingCondition, _unlockedTokenAmount, 0, true));

        uint256 AmountToReceived = _unlockedTokenAmount*(tavaDecimal);

        IERC20(tavaTokenAddress).transferFrom(_msgSender(), address(this), AmountToReceived);
        TotalTokensReceiveable += AmountToReceived;
        emit createdVesting(_receiver, (vestingInfoToWallets[_receiver].length -1), AmountToReceived, _duration, _unlockCnt, _startDt);

    }

    function cancelVesting(address _receiver, uint256 _vestingIdx) 
        external override onlyOwner
    {
        require(sentTavasToAdr(_receiver, _vestingIdx) == 0, "cancelVesting_ERR01");
        uint256 _elapsedDays = getElapsedDays(_receiver, _vestingIdx);
        require(_elapsedDays == 0, "cancelVesting_ERR02");

        uint256 TheAmountReceived = (vestingInfoToWallets[_receiver][_vestingIdx].totalAmount)*(tavaDecimal);

        require(TotalTokensReceiveable > TheAmountReceived, "cancelVesting_ERR03");
        TotalTokensReceiveable = TotalTokensReceiveable - TheAmountReceived;
        vestingInfoToWallets[_receiver][_vestingIdx].valid = false;
        emit canceledVesting(_receiver, _vestingIdx);
    }

    function approvalTava(uint256 _amount) 
        external override 
    {
        IERC20(tavaTokenAddress).approve(address(this), _amount*(tavaDecimal));
    }

    function claimVesting(uint256 _vestingIdx) 
        external override notZeroAddress(_msgSender()) nonReentrant returns(uint256 _TokenPayout)
    {
        require(vestingInfoToWallets[_msgSender()][_vestingIdx].valid, "claimVesting_ERR01"); 
        
        uint256 _elapsedDays = getElapsedDays(_msgSender(), _vestingIdx);
        
        require(_elapsedDays > 0, "claimVesting_ERR02");
        
        uint256 _tokensSent = sentTavasToAdr(_msgSender(), _vestingIdx) * tavaDecimal;
        uint256 _totalAmount = vestingInfoToWallets[_msgSender()][_vestingIdx].totalAmount;
        
        require(_totalAmount > _tokensSent, "claimVesting_ERR03");
        
        uint256 _currentAmount = TokensCurrentlyReceiveable(_msgSender(), _vestingIdx); 
        
        require(_currentAmount > 0, "claimVesting_ERR04");

        IERC20(tavaTokenAddress).transfer(_msgSender(), _currentAmount);

        vestingInfoToWallets[_msgSender()][_vestingIdx].tokensSent += _currentAmount;
        TotalTokensReceived += _currentAmount;
        emit claimedVesting(_msgSender(), _vestingIdx, _currentAmount, block.timestamp);

        return _TokenPayout = _currentAmount;
    }

    function claimTava() 
        external override onlyOwner
    {
        uint256 _TavaBalance = IERC20(tavaTokenAddress).balanceOf(address(this));
        IERC20(tavaTokenAddress).transfer(owner(), _TavaBalance);
    }

    function claimTava(uint256 _amount) 
        external override onlyOwner
    {
        IERC20(tavaTokenAddress).transfer(owner(), _amount*(tavaDecimal));
    }
}