// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.9;
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ITavaVesting.sol";

contract TavaVesting is ITavaVesting, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    bytes32 private rootHash;
    address public tavaTokenAddress;
    uint256 public TotalTokensReceived = 0;
    uint256 public TotalTokensReceiveable = 0;
    uint256 constant tavaDecimal = 1 ether;
    
    mapping (address => VestingInfo[]) public vestingInfoToWallets;

    constructor(
        address _tavaTokenAddress
    ) {
        tavaTokenAddress = _tavaTokenAddress;
    }

    // modifier
    modifier notZeroAddress(address caller) {
        require(caller != address(0), "Cannot perform call function for address(0).");
        _;
    }

    // TAVA 잔액 조회
    function BalanceToAddress(address account) 
        external view returns(uint256)
    {
        return IERC20(tavaTokenAddress).balanceOf(account);
    }
    
    // public
    function TokensCurrentlyReceiveable(address _receiver, uint256 _vestingIdx) 
        public view override returns(uint256 _ReciveableTokens)
    {
        VestingCondition memory _vestingCondition = vestingInfoToWallets[_receiver][_vestingIdx].vestingCondition;
        uint256 _elapsedDays = getElapsedDays(_receiver, _vestingIdx);
        uint256 _TotalAmount = vestingInfoToWallets[_receiver][_vestingIdx].TotalAmount;
        if(_elapsedDays > _vestingCondition.unlockCnt){
            _elapsedDays = _vestingCondition.unlockCnt;
        }

        if(_elapsedDays == 0) {
            return 0;
        }

        uint256 _tokensPerStage = _TotalAmount.mul(tavaDecimal).div(_vestingCondition.unlockCnt);
        uint256 receiveableTava = _tokensPerStage.mul(_elapsedDays);
        uint256 receivedTava = sentTavasToAdr(_receiver, _vestingIdx).mul(tavaDecimal);

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
        if(block.timestamp > _vestingCondition.StartDt) {
            return (block.timestamp - _vestingCondition.StartDt).div(_duration * 1 days);
        } else {
            return 0;
        }
    }
    
    function sentTavasToAdr(address _receiver, uint256 _vestingIdx) 
        public view override returns(uint256 _sentTavas)
    {
        return _sentTavas = vestingInfoToWallets[_receiver][_vestingIdx].tokensSent;
    }
    // public end

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
        uint256 _StartDt
    ) 
        external override onlyOwner notZeroAddress(_receiver)
    {
        require(_unlockedTokenAmount > 0, "setVesting_ERR01");
        require(_duration > 0, "setVesting_ERR02");
        require(_unlockCnt > 0, "setVesting_ERR03");
        VestingCondition memory _vestingCondition = VestingCondition(_duration, _unlockCnt, _StartDt);
        vestingInfoToWallets[_receiver].push(VestingInfo(_vestingCondition, _unlockedTokenAmount, 0, true));

        uint256 AmountToReceived = _unlockedTokenAmount.mul(tavaDecimal);

        IERC20(tavaTokenAddress).transferFrom(_msgSender(), address(this), AmountToReceived);
        TotalTokensReceiveable += AmountToReceived;
        emit createdVesting(_receiver, vestingInfoToWallets[_receiver].length.sub(1), AmountToReceived, _duration, _unlockCnt, _StartDt);

    }

    function cancelVesting(address _receiver, uint256 _vestingIdx) 
        external override onlyOwner
    {
        require(sentTavasToAdr(_receiver, _vestingIdx) == 0, "cancelVesting_ERR01");
        uint256 _elapsedDays = getElapsedDays(_receiver, _vestingIdx);
        require(_elapsedDays == 0, "cancelVesting_ERR02");

        uint256 TheAmountReceived = (vestingInfoToWallets[_receiver][_vestingIdx].TotalAmount).mul(tavaDecimal);

        TotalTokensReceiveable = TotalTokensReceiveable.sub(TheAmountReceived);
        vestingInfoToWallets[_receiver][_vestingIdx].valid = false;
        emit canceledVesting(_receiver, _vestingIdx);
    }

    function approvalTava(uint256 _amount) 
        external override 
    {
        IERC20(tavaTokenAddress).approve(address(this), _amount);
    }

    function claimVesting(uint256 _vestingIdx) 
        external override notZeroAddress(_msgSender()) nonReentrant returns(uint256 _TokenPayout)
    {
        require(vestingInfoToWallets[_msgSender()][_vestingIdx].valid, "claimVesting_ERR01");   // 취소된 베스팅인지 확인
        
        uint256 _elapsedDays = getElapsedDays(_msgSender(), _vestingIdx);
        
        require(_elapsedDays > 0, "claimVesting_ERR02"); // 경과시간이 duration 을 최초 1번 지난 경우 경과일(days 단위 표시)
        
        uint256 _tokensSent = sentTavasToAdr(_msgSender(), _vestingIdx); // 단위 ether
        uint256 _TotalAmount = vestingInfoToWallets[_msgSender()][_vestingIdx].TotalAmount; // 단위 ether
        
        require(_TotalAmount > _tokensSent, "claimVesting_ERR03");
        
        uint256 _currentAmount = TokensCurrentlyReceiveable(_msgSender(), _vestingIdx); // 단위 wei
        
        require(_currentAmount > 0, "claimVesting_ERR04");

        IERC20(tavaTokenAddress).transfer(_msgSender(), _currentAmount);

        //uint256 _currentAmountToTava = _currentAmount.div(tavaDecimal); // 단위 ether
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
        IERC20(tavaTokenAddress).transfer(owner(), _amount.mul(tavaDecimal));
    }
}