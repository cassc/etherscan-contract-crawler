pragma solidity ^0.8.12;

import "openzeppelin-contracts/access/Ownable.sol";
import "openzeppelin-contracts/token/ERC20/IERC20.sol";
import "openzeppelin-contracts/token/ERC20/ERC20.sol";
import "openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";

contract ShareManager is Ownable, ERC20 {
    using SafeERC20 for IERC20;
    
    address public PROJECT_REWARDS;
    IERC20 private immutable TOKEN;
    uint256 private immutable TOKEN_DECIMALS;

    bool public actionsLocked = false;

    mapping(address => uint256) public lastDeposit;

    uint256 constant DIVISOR = 10000;

    uint256 public EARY_LEAVE_FEE = 2000;
    uint256 public EARLY_LEAVE_PERIOD = 60 days;

    uint256 public DEPOSIT_FEE = 150;
    uint256 public PERFROMANCE_FEE = 1500;

    uint256 public MIN_DEPOSIT = 0;
    uint256 public MAX_DEPOSIT = type(uint256).max;

    uint256 public virtualTokenBalance = 0;

    modifier onlyWhileLocked {
        require(actionsLocked, "Cannot operate while unlocked");
        _;
    }

    modifier onlyWhileUnlocked {
        require(!actionsLocked, "Cannot operate while locked");
        _;
    }

    event FundsSentToTrading(uint256 timestamp, uint256 funds);
    event SPREvent(uint256 timestamp, bool win, uint256 assetsDelta, uint256 sharePrice, uint256 virtualBalanceBefore);
    event Deposit(address indexed user, address indexed ref, uint256 timestamp, uint256 assetAmount, uint256 sharesAmount, uint256 feeShares);
    event Withdraw(address indexed user, uint256 timestamp, uint256 assetAmount, uint256 sharesAmount, uint256 feeShares);

    constructor(
        address _rewardsAddress,
        IERC20 _token,
        uint256 _tokenDecimals
    ) ERC20("Summit FX Share", "FXS") {
        PROJECT_REWARDS = _rewardsAddress;
        TOKEN = _token;
        TOKEN_DECIMALS = _tokenDecimals;
    }

    // Parameter adjusting
    function changeEarlyLeavePeriod(uint256 _newPeriod) external onlyOwner {
        EARLY_LEAVE_PERIOD = _newPeriod;
    }

    function changeEarlyLeaveFee(uint256 _newFee) external onlyOwner {
        EARY_LEAVE_FEE = _newFee;
    }

    function changeDepositFee(uint256 _newFee) external onlyOwner {
        DEPOSIT_FEE = _newFee;
    }

    function changePerfromanceFee(uint256 _newFee) external onlyOwner {
        PERFROMANCE_FEE = _newFee;
    }

    function changeMinDeposit(uint256 _minDeposit) external onlyOwner {
        MIN_DEPOSIT = _minDeposit;
    }

    function changeMaxDeposit(uint256 _maxDeposit) external onlyOwner {
        MAX_DEPOSIT = _maxDeposit;
    }

    function changeRewardsAddress(address _newAddress) external onlyOwner {
        PROJECT_REWARDS = _newAddress;
    }

    // SPR events and cycle

    // This function should only be used in case of an "SPR cycle brick"
    function toggleActionLock(bool _tog) external onlyOwner {
        actionsLocked = _tog;
    }

    function resetAddressEarlyLeaveFee(address _who) external onlyOwner {
        lastDeposit[_who] = 0;
    }

    function withdrawFundsAndLock() external onlyOwner onlyWhileUnlocked {
        actionsLocked = true;

        uint256 _bal = TOKEN.balanceOf(address(this));
        TOKEN.safeTransfer(owner(), _bal);

        emit FundsSentToTrading(block.timestamp, _bal);
    }

    function doSPR(bool _win, uint256 _assetsDelta) external onlyOwner onlyWhileLocked {
        uint256 _totalShares = totalSupply();
        uint256 _vbb = virtualTokenBalance;

        if (!_win) {
            virtualTokenBalance -= _assetsDelta;
        } else {
            // Calculate performance fee
            uint256 _toBeAdded = (DIVISOR - PERFROMANCE_FEE) * _assetsDelta / DIVISOR;
            uint256 _virtualSharePrice = _calculateSharePrice(_totalShares, virtualTokenBalance + _toBeAdded);
            uint256 _toMintPerformanceFee = _getSharesToMint(_assetsDelta - _toBeAdded, _virtualSharePrice);
            if (_toMintPerformanceFee > 0) {
                _mint(PROJECT_REWARDS, _toMintPerformanceFee);
            }
            virtualTokenBalance += _assetsDelta;
        }

        actionsLocked = false;
        emit SPREvent(block.timestamp, _win, _assetsDelta, _calculateSharePrice(totalSupply(), virtualTokenBalance), _vbb);
    }

    // mechanics

    function deposit(uint256 _amount, address _ref) external onlyWhileUnlocked {
        require(_amount >= MIN_DEPOSIT && _amount <= MAX_DEPOSIT && _amount > 0, "Deposit too big/small");
        require(_ref != msg.sender, "Cannot ref yourself");
        TOKEN.safeTransferFrom(msg.sender, address(this), _amount);
        lastDeposit[msg.sender] = block.timestamp;

        uint256 _sharePrice = _calculateSharePrice(totalSupply(), virtualTokenBalance);
        uint256 _toMint = _getSharesToMint(_amount, _sharePrice);
        uint256 _depositFee = _toMint * DEPOSIT_FEE / DIVISOR;
        uint256 _toMintUser = _toMint - _depositFee;

        virtualTokenBalance += _amount;
        _mint(msg.sender, _toMintUser);
        if (_depositFee > 0) {
            _mint(_ref == address(0) ? PROJECT_REWARDS : _ref, _depositFee);
        }

        emit Deposit(msg.sender, _ref, block.timestamp, _amount, _toMintUser, _depositFee);
    }

    function _withdraw(uint256 _shares, address _toSend) internal {
        require(_shares > 0 && totalSupply() > 0, "Cannot withdraw 0 shares");
        uint256 _sharesToWithdraw = balanceOf(msg.sender) < _shares ? balanceOf(msg.sender) : _shares;

        require(_sharesToWithdraw > 0, "Withdrawing 0");

        uint256 _sharesEarlyLeaveFee = 0;
        if (lastDeposit[msg.sender] + EARLY_LEAVE_PERIOD > block.timestamp) {
            _sharesEarlyLeaveFee = _sharesToWithdraw * EARY_LEAVE_FEE / DIVISOR;
            _sharesToWithdraw -= _sharesEarlyLeaveFee;
            _transfer(msg.sender, PROJECT_REWARDS, _sharesEarlyLeaveFee);
        }

        uint256 _virtualPrice = _calculateSharePrice(totalSupply(), virtualTokenBalance);
        uint256 _toSendValue = _virtualPrice * _sharesToWithdraw / 10**18;

        virtualTokenBalance -= _toSendValue;
        _burn(msg.sender, _sharesToWithdraw);
        TOKEN.safeTransfer(_toSend, _toSendValue);

        emit Withdraw(msg.sender, block.timestamp, _toSendValue, _sharesToWithdraw, _sharesEarlyLeaveFee);
    }

    function withdraw(uint256 _shares, address _toSend) external onlyWhileUnlocked {
        _withdraw(_shares, _toSend);
    }

    function withdrawUnderlying(uint256 _underlying, address _toSend) external onlyWhileUnlocked {
        _withdraw(_underlying * 10**18 / _calculateSharePrice(totalSupply(), virtualTokenBalance), _toSend);
    }

    function _calculateSharePrice(uint256 _totalShares, uint256 _totalTokens) internal view returns (uint256) {
        return _totalShares == 0 ? 10**TOKEN_DECIMALS : (_totalTokens * 10**18) / _totalShares;
    }

    function _getSharesToMint(uint256 _assetAmount, uint256 _sharePrice) internal pure returns (uint256) {
        return _assetAmount * 10**18 / _sharePrice;
    }

    // Frontend functions
    function getSharePrice() external view returns (uint256) {
        return _calculateSharePrice(totalSupply(), virtualTokenBalance);
    }

    function getAddressUnderlyingBalance(address _account) external view returns (uint256) {
        return _calculateSharePrice(totalSupply(), virtualTokenBalance) * balanceOf(_account) / 10**18;
    }

    function convertSharesToUnderlying(uint256 _shares) external view returns (uint256) {
        return _calculateSharePrice(totalSupply(), virtualTokenBalance) * _shares / 10**18;
    }

    function convertUnderlyingToShares(uint256 _underlying) external view returns (uint256) {
        return _underlying * 10**18 / _calculateSharePrice(totalSupply(), virtualTokenBalance);
    }

    // ERC20 overrides for share

    function transfer(address,uint256) public pure override returns (bool) {
        revert();
    }

    function approve(address,uint256) public pure override returns (bool) {
        revert();
    }
    function transferFrom(
        address,
        address,
        uint256
    ) public pure override returns (bool) {
        revert();
    }

    function increaseAllowance(address,uint256) public pure override returns (bool) {
        revert();
    }

    function decreaseAllowance(address,uint256) public pure override returns (bool) {
        revert();
    }
}