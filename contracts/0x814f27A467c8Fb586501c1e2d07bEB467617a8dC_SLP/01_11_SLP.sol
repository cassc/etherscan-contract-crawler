// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.13;

// https://street-machine.com
// https://t.me/streetmachineportal
// https://twitter.com/erc_arcade

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/ISLP.sol";
import "./interfaces/IERC20BackwardsCompatible.sol";
import "./interfaces/IFeeTracker.sol";
import "./interfaces/IesSMCIncentiveManager.sol";

contract SLP is ISLP, ERC20, Ownable, ReentrancyGuard {
    error PoolNotPublic();
    error PoolAlreadyPublic();
    error InsufficientUSDBalance(uint256 _amountUSDT, uint256 _balance);
    error InsufficientUSDAllowance(uint256 _amountUSDT, uint256 _allowance);
    error InsufficientSLPBalance(uint256 _amountSLP, uint256 _balance);
    error InsufficientSLPAllowance(uint256 _amountSLP, uint256 _allowance);
    error ZeroDepositAmount();
    error ZeroWithdrawalAmount();
    error OnlyHouse(address _caller);
    error AlreadyInitialized();
    error NotInitialized();
    error DepositFeeTooHigh();
    error WithdrawFeeTooHigh();
    error FeesRemoved();

    IERC20BackwardsCompatible public immutable usdt;

    uint256 public depositFee = 100;
    uint256 public withdrawFee = 100;
    bool public feesRemoved;
    IFeeTracker public ssmcFees;
    IFeeTracker public bsmcFees;
    IFeeTracker public essmcFees;
    IesSMCIncentiveManager public essmcIncentiveManager;

    mapping (address => uint256) public depositsByAccount;
    mapping (address => uint256) public withdrawalsByAccount;
    uint256 public deposits;
    uint256 public withdrawals;
    uint256 public inflow;
    uint256 public outflow;
    uint256 public depositFeesCollected;
    uint256 public withdrawalFeesCollected;

    address public house;

    event Deposit(address indexed _account, uint256 indexed _amountUSDT, uint256 indexed _timestamp, uint256 _amountSLP, uint256 _fee);
    event Withdrawal(address indexed _account, uint256 indexed _amountUSDT, uint256 indexed _timestamp, uint256 _amountSLP, uint256 _fee);
    event Win(address indexed _account, uint256 indexed _game, uint256 indexed _timestamp, uint256 _requestId, uint256 _amount);
    event Loss(address indexed _account, uint256 indexed _game, uint256 indexed _timestamp, uint256 _requestId, uint256 _amount);

    mapping (address => bool) public depositorWhitelist;
    bool public open;

    bool private initialized;

    modifier onlyHouse() {
        if (msg.sender != house) {
            revert OnlyHouse(msg.sender);
        }
        _;
    }

    constructor(address _USDT) ERC20(unicode"Street Machine 街道机器 LP", "SLP") {
        usdt = IERC20BackwardsCompatible(_USDT);
    }

    function initialize(address _house, address _sSMCFees, address _bSMCFees, address _esSMCFees) external nonReentrant onlyOwner {
        if (initialized) {
            revert AlreadyInitialized();
        }
        house = _house;
        ssmcFees = IFeeTracker(_sSMCFees);
        bsmcFees = IFeeTracker(_bSMCFees);
        essmcFees = IFeeTracker(_esSMCFees);
        usdt.approve(_sSMCFees, type(uint256).max);
        usdt.approve(_bSMCFees, type(uint256).max);
        usdt.approve(_esSMCFees, type(uint256).max);
        initialized = true;
    }

    function deposit(uint256 _amountUSDT) external nonReentrant {
        if (!open && !depositorWhitelist[msg.sender]) {
            revert PoolNotPublic();
        }
        if (_amountUSDT == 0) {
            revert ZeroDepositAmount();
        }
        if (_amountUSDT > usdt.balanceOf(msg.sender)) {
            revert InsufficientUSDBalance(_amountUSDT, usdt.balanceOf(msg.sender));
        }
        if (_amountUSDT > usdt.allowance(msg.sender, address(this))) {
            revert InsufficientUSDAllowance(_amountUSDT, usdt.balanceOf(msg.sender));
        }

        uint256 _fee;
        if (depositFee > 0) {
            // some accounts have different fees
            _fee = _amountUSDT * depositFee / 10000;
            usdt.transferFrom(msg.sender, address(this), _fee);
            _depositYield(0, _fee);
            _amountUSDT -= _fee;
            depositFeesCollected += _fee;
        }

        uint256 _supplySLP = this.totalSupply();
        uint256 _amountSLP = _supplySLP == 0 ? _amountUSDT : (_amountUSDT * _supplySLP) / usdt.balanceOf(address(this));

        _mint(msg.sender, _amountSLP);
        usdt.transferFrom(msg.sender, address(this), _amountUSDT);
        deposits += _amountUSDT;
        depositsByAccount[msg.sender] += _amountUSDT;
        try essmcIncentiveManager.registerSLPDeposit(msg.sender, _amountUSDT, block.timestamp, _amountSLP) {} catch {}
        emit Deposit(msg.sender, _amountUSDT, block.timestamp, _amountSLP, _fee);
    }

    function withdraw(uint256 _amountSLP) external nonReentrant {
        if (_amountSLP == 0) {
            revert ZeroWithdrawalAmount();
        }
        if (_amountSLP > this.balanceOf(msg.sender)) {
            revert InsufficientSLPBalance(_amountSLP, this.balanceOf(msg.sender));
        }
        if (_amountSLP > this.allowance(msg.sender, address(this))) {
            revert InsufficientSLPAllowance(_amountSLP, this.balanceOf(msg.sender));
        }

        uint256 _amountUSDT = (_amountSLP * usdt.balanceOf(address(this))) / this.totalSupply();

        uint256 _fee;
        if (withdrawFee > 0) {
            // some accounts have different fees
            _fee = _amountUSDT * withdrawFee / 10000;
            _depositYield(1, _fee);
            _amountUSDT -= _fee;
            withdrawalFeesCollected += _fee;
        }

        _burn(msg.sender, _amountSLP);
        usdt.transfer(msg.sender, _amountUSDT);
        withdrawals += _amountUSDT;
        withdrawalsByAccount[msg.sender] += _amountUSDT;
        try essmcIncentiveManager.registerSLPWithdrawal(msg.sender, _amountUSDT, block.timestamp, _amountSLP) {} catch {}
        emit Withdrawal(msg.sender, _amountUSDT, block.timestamp, _amountSLP, _fee);
    }

    function _depositYield(uint256 _source, uint256 _fee) private {
        bsmcFees.depositYield(_source, _fee * 7000 / 10000);
        uint256 _fee15Pct = _fee * 1500 / 10000;
        ssmcFees.depositYield(_source, _fee15Pct);
        essmcFees.depositYield(_source, _fee15Pct);
    }

    function payWin(address _account, uint256 _game, uint256 _requestId, uint256 _amount) external override nonReentrant onlyHouse {
        usdt.transfer(_account, _amount);
        outflow += _amount;
        emit Win(_account, _game, block.timestamp, _requestId, _amount);
    }

    function receiveLoss(address _account, uint256 _game, uint256 _requestId, uint256 _amount) external override nonReentrant onlyHouse {
        usdt.transferFrom(msg.sender, address(this), _amount);
        inflow += _amount;
        emit Loss(_account, _game, block.timestamp, _requestId, _amount);
    }

    function setDepositFee(uint256 _depositFee) external nonReentrant onlyOwner {
        if (feesRemoved) {
            revert FeesRemoved();
        }
        if (_depositFee > 100) {
            revert DepositFeeTooHigh();
        }
        depositFee = _depositFee;
    }

    function setWithdrawFee(uint256 _withdrawFee) external nonReentrant onlyOwner {
        if (feesRemoved) {
            revert FeesRemoved();
        }
        if (_withdrawFee > 100) {
            revert WithdrawFeeTooHigh();
        }
        withdrawFee = _withdrawFee;
    }

    function removeFees() external nonReentrant onlyOwner {
        if (feesRemoved) {
            revert FeesRemoved();
        }
        depositFee = 0;
        withdrawFee = 0;
        feesRemoved = true;
    }

    function setDepositorWhitelist(address _depositor, bool _isWhitelisted) external nonReentrant onlyOwner {
        depositorWhitelist[_depositor] = _isWhitelisted;
    }

    function setEsSMCIncentiveManager(address _essmcIncentiveManager) external nonReentrant onlyOwner {
        essmcIncentiveManager = IesSMCIncentiveManager(_essmcIncentiveManager);
    }

    function goPublic() external nonReentrant onlyOwner {
        if (open) {
            revert PoolAlreadyPublic();
        }
        open = true;
    }

    function getSLPFromUSDT(uint256 _amountUSDT) external view returns (uint256) {
        uint256 _supplySLP = this.totalSupply();
        return _supplySLP == 0 ? _amountUSDT : (_amountUSDT * _supplySLP) / usdt.balanceOf(address(this));
    }

    function getUSDTFromSLP(uint256 _amountSLP) external view returns (uint256) {
        return (_amountSLP * usdt.balanceOf(address(this))) / this.totalSupply();
    }

    function getDepositsByAccount(address _account) external view returns (uint256) {
        return depositsByAccount[_account];
    }

    function getWithdrawalsByAccount(address _account) external view returns (uint256) {
        return withdrawalsByAccount[_account];
    }

    function getDeposits() external view returns (uint256) {
        return deposits;
    }

    function getWithdrawals() external view returns (uint256) {
        return withdrawals;
    }

    function getInflow() external view returns (uint256) {
        return inflow;
    }

    function getOutflow() external view returns (uint256) {
        return outflow;
    }

    function getFees() external view returns (uint256, uint256) {
        return (depositFee, withdrawFee);
    }

    function getFeesCollected() external view returns (uint256, uint256, uint256) {
        return (depositFeesCollected + withdrawalFeesCollected, depositFeesCollected, withdrawalFeesCollected);
    }

    function getEsSMCIncentiveManager() external view returns (address) {
        return address(essmcIncentiveManager);
    }

    function getOpen() external view returns (bool) {
        return open;
    }

    receive() external payable {}
}