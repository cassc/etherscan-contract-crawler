// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "@openzeppelin/contracts/GSN/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./external/IUniswapV2Router02.sol";
import "./external/IUniswapV2Factory.sol";

library GeroConstants {
    string private constant _name = "GeroWallet";
    string private constant _symbol = "GERO";
    uint8 private constant _decimals = 18;
    address private constant _tokenOwner = 0x94DfBE39556B7d5b66Dc6B35aDC3A2F4C9B29a1A;

    function getName() internal pure returns (string memory) {
        return _name;
    }

    function getSymbol() internal pure returns (string memory) {
        return _symbol;
    }

    function getDecimals() internal pure returns (uint8) {
        return _decimals;
    }

    function getTokenOwner() internal pure returns (address) {
        return _tokenOwner;
    }

}

contract GERO is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    uint256 _totalSupply = 5 * 10**8 * 10**18;
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    IUniswapV2Router02 public uniRouter;
    IUniswapV2Factory public uniFactory;
    address public launchPool;

    uint256 private _tradingTime;
    uint256 private _restrictionLiftTime;
    uint256 private _maxRestrictionAmount = 1000000 * 10**18;
    mapping (address => bool) private _isWhitelisted;
    mapping (address => bool) private _openSender;
    mapping (address => uint256) private _lastTx;

    constructor () public {
        uniRouter = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniFactory = IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
        launchPool = uniFactory.createPair(address(uniRouter.WETH()),address(this));
        _balances[GeroConstants.getTokenOwner()] = _totalSupply; 
        emit Transfer(address(0), GeroConstants.getTokenOwner(), _totalSupply);
    }

    function name() public view returns (string memory) {
        return GeroConstants.getName();
    }

    function symbol() public view returns (string memory) {
        return GeroConstants.getSymbol();
    }

    function decimals() public view returns (uint8) {
        return GeroConstants.getDecimals();
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "GERO: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "GERO: decreased allowance below zero"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) private launchRestrict(sender, recipient, amount) {
        require(sender != address(0), "GERO: transfer from the zero address");
        require(recipient != address(0), "GERO: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "GERO: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "GERO: approve from the zero address");
        require(spender != address(0), "GERO: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function setRestrictionAmount(uint256 amount) external onlyOwner() {
        _maxRestrictionAmount = amount;
    }

    function whitelistAccount(address account) external onlyOwner() {
        _isWhitelisted[account] = true;
    }

    function addSender(address account) external onlyOwner() {
        _openSender[account] = true;
    }

    modifier launchRestrict(address sender, address recipient, uint256 amount) {
        if (_tradingTime == 0) {
            if (balanceOf(launchPool) > 0) {
                _tradingTime = now;
                _restrictionLiftTime = now.add(10*60);
                require(amount <= _maxRestrictionAmount, "GERO: amount greater than max limit");
                require(tx.gasprice <= 432000000000,"GERO: gas price above limit");
                if (!_isWhitelisted[sender] && !_isWhitelisted[recipient]) {
                    require(_lastTx[sender].add(60) <= now && _lastTx[recipient].add(60) <= now, "GERO: only one tx/min in restricted mode");
                    _lastTx[sender] = now;
                    _lastTx[recipient] = now;
                } else if (!_isWhitelisted[recipient]){
                    require(_lastTx[recipient].add(60) <= now, "GERO: only one tx/min in restricted mode");
                    _lastTx[recipient] = now;
                } else if (!_isWhitelisted[sender]) {
                    require(_lastTx[sender].add(60) <= now, "GERO: only one tx/min in restricted mode");
                    _lastTx[sender] = now;
                }
            } else {
                require(_openSender[sender],"GERO: transfers are disabled");
            }
        } else if (_tradingTime <= now && _restrictionLiftTime > now) {
            require(amount <= _maxRestrictionAmount, "GERO: amount greater than max limit");
            require(tx.gasprice <= 432000000000,"GERO: gas price above limit");
            if (!_isWhitelisted[sender] && !_isWhitelisted[recipient]) {
                require(_lastTx[sender].add(60) <= now && _lastTx[recipient].add(60) <= now, "GERO: only one tx/min in restricted mode");
                _lastTx[sender] = now;
                _lastTx[recipient] = now;
            } else if (!_isWhitelisted[recipient]){
                require(_lastTx[recipient].add(60) <= now, "GERO: only one tx/min in restricted mode");
                _lastTx[recipient] = now;
            } else if (!_isWhitelisted[sender]) {
                require(_lastTx[sender].add(60) <= now, "GERO: only one tx/min in restricted mode");
                _lastTx[sender] = now;
            }
        }
        _;
    }
}