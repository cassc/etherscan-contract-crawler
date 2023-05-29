// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "@openzeppelin/contracts/GSN/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./external/IUniswapV2Router02.sol";
import "./external/IUniswapV2Factory.sol";

library CSWAPConstants {
    string private constant _name = "CardSwap";
    string private constant _symbol = "CSWAP";
    uint8 private constant _decimals = 18;

    function getName() internal pure returns (string memory) {
        return _name;
    }

    function getSymbol() internal pure returns (string memory) {
        return _symbol;
    }

    function getDecimals() internal pure returns (uint8) {
        return _decimals;
    }
}

contract CSWAP is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    uint256 _totalSupply;
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    mapping (address => bool) private _isWhitelisted;
    mapping (address => uint256) private _lastTx;

    IUniswapV2Router02 public uniRouter;
    IUniswapV2Factory public uniFactory;
    address public launchPool;
    address public farmer;    

    constructor () public {
        uniRouter = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniFactory = IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
        launchPool = uniFactory.createPair(address(uniRouter.WETH()),address(this));
    }

    function name() public view returns (string memory) {
        return CSWAPConstants.getName();
    }

    function symbol() public view returns (string memory) {
        return CSWAPConstants.getSymbol();
    }

    function decimals() public view returns (uint8) {
        return CSWAPConstants.getDecimals();
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "CSWAP: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "CSWAP: decreased allowance below zero"));
        return true;
    }

    function mint(address account, uint256 amount) public onlyFarmer returns (bool) {
        require(account != address(0), "CSWAP: cannot mint to zero address");
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) private restrict(sender, recipient) {
        require(sender != address(0), "CSWAP: transfer from the zero address");
        require(recipient != address(0), "CSWAP: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "CSWAP: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "CSWAP: approve from the zero address");
        require(spender != address(0), "CSWAP: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function whitelistAccount(address account) external onlyOwner() {
        _isWhitelisted[account] = true;
    }

    // Contract ownership has to be mandatorily moved to a multisig to ensure no malicious activity can be performed
    function setFarmer(address _farmer) external onlyOwner() {
        farmer = _farmer;
    }

    modifier restrict(address sender, address recipient) {
        if (!_isWhitelisted[sender] && !_isWhitelisted[recipient]) {
            require(_lastTx[sender] < now && _lastTx[recipient] < now, "CSWAP: no simultaneous txes");
            _lastTx[sender] = now;
            _lastTx[recipient] = now;
        } else if (!_isWhitelisted[recipient]){
            require(_lastTx[recipient] < now, "CSWAP: no simultaneous txes");
            _lastTx[recipient] = now;
        } else if (!_isWhitelisted[sender]) {
            require(_lastTx[sender] < now, "CSWAP: no simultaneous txes");
            _lastTx[sender] = now;
        }
        _;
    }

    modifier onlyFarmer() {
        require(_msgSender() == farmer, "CSWAP: Not the farming contract");
        _;
    }
}