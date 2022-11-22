// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.6.11;

import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";

import "../lib/interfaces/IAETH.sol";
import "../lib/Lockable.sol";
import "../lib/Ownable_R1.sol";

contract FETH_R16 is Ownable_R1, IERC20, Lockable {

    using SafeMath for uint256;

    event Locked(address account, uint256 amount);
    event Unlocked(address account, uint256 amount);
    event GlobalPoolAddressChanged(address prevValue, address newValue);
    event AETHContractChanged(address prevValue, address newValue);
    event NameAndSymbolChanged(string name, string symbol);
    event SwapFeeParamsChanged(address operator, uint256 ratio);

    string private _name;
    string private _symbol;

    // deleted fields
    uint8 private _decimals; // deleted

    address private _globalPoolContract;
    mapping(address => uint256) private _shares;
    mapping(address => mapping(address => uint256)) private _allowances;

    // deleted fields
    uint256 private _totalRewards; // deleted
    uint256 private _totalShares; // deleted
    uint256 private _totalSent; // deleted
    uint256 private _totalDeposit; // deleted

    address private _operator;

    // deleted fields
    address private _bscBridgeContract; // deleted
    uint256 _balanceRatio; // deleted

    address private _aEthContract;
    address private _swapFeeOperator;
    uint256 private _swapFeeRatio;

    modifier onlyOperator() {
        require(msg.sender == owner() || msg.sender == _operator, "Operator: not allowed");
        _;
    }

    function initialize(string memory name, string memory symbol, address operator) public initializer {
        __Ownable_init();
        _operator = operator;
        _name = name;
        _symbol = symbol;
    }

    function lockedSharesOf(address account) public view returns (uint256) {
        return _shares[account];
    }

    function ratio() external view returns (uint256) {
        return IAETH(_aEthContract).ratio();
    }

    function isRebasing() external pure returns (bool) {
        return true;
    }

    function lockShares(uint256 shares) external {
        address spender = msg.sender;
        // transfer tokens from aETHc to aETHb
        require(IERC20(_aEthContract).transferFrom(spender, address(this), shares), "can't transfer");
        // calc swap fee (default swap fee ratio is 0.3%=0.3/100*1e18, fee can't be greater than 1%)
        uint256 fee = shares.mul(_swapFeeRatio).div(1e18);
        if (msg.sender == _swapFeeOperator) {
            fee = 0;
        }
        uint256 sharesWithFee = shares.sub(fee);
        // increase senders and operator balances
        _shares[_swapFeeOperator] = _shares[_swapFeeOperator].add(fee);
        _shares[spender] = _shares[spender].add(sharesWithFee);
        emit Locked(spender, shares);
    }

    function lockSharesFor(address spender, address account, uint256 shares) external onlyGlobalPool {
        require(spender == msg.sender, "invalid spender");
        _shares[account] = _shares[account].add(shares);
        require(IERC20(_aEthContract).transferFrom(spender, address(this), shares), "can't transfer");
        emit Locked(account, shares);
    }

    function unlockShares(uint256 shares) external {
        address account = address(msg.sender);
        // make sure user has enough balance
        require(_shares[account] >= shares, "insufficient balance");
        // calc swap fee
        uint256 fee = shares.mul(_swapFeeRatio).div(1e18);
        if (msg.sender == _swapFeeOperator) {
            fee = 0;
        }
        uint256 sharesWithFee = shares.sub(fee);
        // update balances
        _shares[_swapFeeOperator] = _shares[_swapFeeOperator].add(fee);
        _shares[account] = _shares[account].sub(shares);
        // transfer tokens to the user
        require(IERC20(_aEthContract).transfer(account, sharesWithFee), "can't transfer");
        emit Unlocked(account, shares);
    }

    function totalSupply() public view override returns (uint256) {
        uint256 totalLocked = IERC20(_aEthContract).balanceOf(address(this));
        return totalLocked.mul(1e18).div(IAETH(_aEthContract).ratio());
    }

    function balanceOf(address account) public view override returns (uint256) {
        uint256 shares = _shares[account];
        return shares.mul(1e18).div(IAETH(_aEthContract).ratio());
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        return _transfer(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _allowances[sender][_msgSender()] = _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance");
        _transfer(sender, recipient, amount);
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        uint256 shares = amount.mul(IAETH(_aEthContract).ratio()).add(1e18 - 1).div(1e18);
        _shares[sender] = _shares[sender].sub(shares, "ERC20: transfer shares exceeds balance");
        _shares[recipient] = _shares[recipient].add(shares);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    modifier onlyGlobalPool() {
        require(_globalPoolContract == msg.sender, "only global pool");
        _;
    }

    function setGlobalPoolAddress(address globalPoolAddress) external onlyOwner {
        address prevValue = _globalPoolContract;
        _globalPoolContract = globalPoolAddress;
        emit GlobalPoolAddressChanged(prevValue, globalPoolAddress);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function decimals() public view returns (uint8) {
        return 18;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function setAethContract(address aEthContract) external onlyOwner {
        address prevValue = _aEthContract;
        _aEthContract = aEthContract;
        emit AETHContractChanged(prevValue, aEthContract);
    }

    function setNameAndSymbol(string memory new_name, string memory new_symbol) public onlyOperator {
        _name = new_name;
        _symbol = new_symbol;
        emit NameAndSymbolChanged(_name, _symbol);
    }

    function changeSwapFeeParams(address swapFeeOperator, uint256 swapFeeRatio) public onlyOwner {
        // 1%=1/100*1e18=10000000000000000
        require(swapFeeRatio <= 10000000000000000, "not greater than 1%");
        _swapFeeOperator = swapFeeOperator;
        _swapFeeRatio = swapFeeRatio;
        emit SwapFeeParamsChanged(_swapFeeOperator, _swapFeeRatio);
    }

    function getSwapFeeRatio() public view returns (uint256) {
        return _swapFeeRatio;
    }

    modifier onlySwapFeeOperator() {
        require(msg.sender == _swapFeeOperator);
        _;
    }
}