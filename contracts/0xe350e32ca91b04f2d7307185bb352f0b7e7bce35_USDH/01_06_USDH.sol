// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "forge-std/console.sol";

contract USDH is IERC20, Ownable, ReentrancyGuard {
    uint256 internal constant max256 = type(uint256).max;
    uint128 internal constant max128 = type(uint128).max;

    string private constant _name = "Hoard Dollar";
    string private constant _symbol = "USDH";
    uint8 private constant _decimals = 18;

    uint256 public _totalSupply;

    mapping (address => bool) public wasCollateral;
    mapping (address => bool) public collateralWhitelist;
    mapping (address => uint256) public collateralDecimals;

    address[] public collateralTypes;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    address public governance;

    modifier onlyGovernance() {
        require(msg.sender == governance);
        _;
    }

    constructor() {
        governance = msg.sender;
        _balances[address(this)] = _totalSupply;
        emit Transfer(address(0), address(this), _totalSupply);
    }

    function mint(address _collateral, uint256 _amount) external nonReentrant {
        require(collateralWhitelist[_collateral]);
        require(_amount > 0);

        uint256 _amountStablecoin = _amount * (10 ** (18 - collateralDecimals[_collateral]));
        IERC20 _Collateral = IERC20(_collateral);
        require(_Collateral.balanceOf(msg.sender) >= _amountStablecoin);
        require(_Collateral.allowance(msg.sender, address(this)) >= _amountStablecoin);
        uint256 _balance = _Collateral.balanceOf(address(this));
        require(_Collateral.transferFrom(msg.sender, address(this), _amountStablecoin), "TF");
        require(_Collateral.balanceOf(address(this)) >= _balance + _amountStablecoin, "TF");

        _totalSupply = _totalSupply + _amount;
        _balances[msg.sender] = _balances[msg.sender] + _amount;
        emit Transfer(address(0), msg.sender, _amount);
    }

    function redeem(uint256 _amount) external nonReentrant returns (address[] memory) {
        require(_balances[msg.sender] >= _amount && _totalSupply >= _amount);
        _balances[msg.sender] = _balances[msg.sender] - _amount;
        emit Transfer(msg.sender, address(0), _amount);
        _totalSupply = _totalSupply - _amount;

        address[] memory _collateralTypes = new address[](9);

        uint256 _amountStablecoin = _amount;
        uint256 _amountStablecoinPaid;
        uint256 _i;
        while (_amountStablecoin > _amountStablecoinPaid) {
            (address _largestCollateral, uint256 _largestBalance) = getLargestBalance();
            _largestBalance = _largestBalance * (10 ** (18 - collateralDecimals[_largestCollateral]));
            uint256 _amountCollateral = _amountStablecoin > _largestBalance ? _largestBalance : _amountStablecoin;
            _largestBalance = _largestBalance / (10 ** (18 - collateralDecimals[_largestCollateral]));
            try IERC20(_largestCollateral).transfer(msg.sender, _amountCollateral) {} catch {}
            _amountStablecoinPaid = _amountStablecoinPaid + _amountCollateral;
            if (_i < 9) {
                _collateralTypes[_i] = _largestCollateral;
                _i = _i + 1;
            }
        }

        return _collateralTypes;
    }

    function getLargestBalance() public view returns (address, uint256) {
        address _largestCollateral;
        uint256 _largestBalance;

        uint256 collateralTypesNum = collateralTypes.length;

        for (uint256 _i = 0; _i < collateralTypesNum; _i++) {
            address _collateral = collateralTypes[_i];
            uint256 _balance = IERC20(_collateral).balanceOf(address(this));
            if (_balance > _largestBalance) {
                _largestCollateral = _collateral;
                _largestBalance = _balance;
            }
        }

        return (_largestCollateral, _largestBalance);
    }

    function getCollateral(address _collateral) external view returns (bool, uint256, uint256) {
        return (collateralWhitelist[_collateral], collateralDecimals[_collateral], IERC20(_collateral).balanceOf(address(this)));
    }

    function setCollateral(address _collateralAddress, bool _collateralEnabled, uint256 _collateralDecimals) external onlyGovernance {
        require(_collateralDecimals <= 18);
        if (_collateralEnabled && !wasCollateral[_collateralAddress]) {
            collateralTypes.push(_collateralAddress);
            wasCollateral[_collateralAddress] = true;
        }
        collateralWhitelist[_collateralAddress] = _collateralEnabled;
        collateralDecimals[_collateralAddress] = _collateralDecimals;
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function decimals() external pure returns (uint8) {
        return _decimals;
    }

    function symbol() external pure returns (string memory) {
        return _symbol;
    }

    function name() external pure returns (string memory) {
        return _name;
    }

    function getOwner() external view returns (address) {
        return owner();
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function allowance(address holder, address spender) external view override returns (uint256) {
        return _allowances[holder][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, max256);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if (_allowances[sender][msg.sender] != max256) {
            require(_allowances[sender][msg.sender] >= amount, "Insufficient allowance");
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender] - amount;
        }
        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        require(_balances[sender] >= amount, "Insufficient balance");
        _balances[sender] = _balances[sender] - amount;
        _balances[recipient] = _balances[recipient] + amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function rescue(address token) external onlyOwner {
        if (token == 0x0000000000000000000000000000000000000000) {
            payable(msg.sender).call{value: address(this).balance}("");
        } else {
            require(!wasCollateral[token], "Can't withdraw collateral");
            IERC20 Token = IERC20(token);
            Token.transfer(msg.sender, Token.balanceOf(address(this)));
        }
    }

    function setGovernance(address governanceContract) external {
        require(msg.sender == (governance == owner() ? owner() : governance));
        governance = governanceContract;
    }

    receive() external payable {}
}