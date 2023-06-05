// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./utils/TeamAccess.sol";
import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IUniswapV2Router02.sol";

contract EZCodeAI is Context, IERC20, IERC20Metadata, Ownable, TeamAccess {
    using SafeMath for uint256;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    string private constant _name = "EZ Code AI";
    string private constant _symbol = "EZC";

    IUniswapV2Router02 private _uniswapV2Router;
    address private uniswapV2Pair;
    address private _taxWallet;
    mapping(address => bool) private _isExcludedFromFee;

    uint8 private constant _decimals = 9;
    uint32 public buyTax = 50000;
    uint32 public sellTax = 200000;
    uint256 private _totalSupply = 10 ** 9 * 10 ** _decimals;
    uint256 public maxTrxnAmount = _totalSupply.mul(2).div(100);
    uint256 public maxWalletSize = _totalSupply.mul(2).div(100);
    bool private inSwap;

    modifier lockTheSwap() {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor(address uniswapRouter) {
        require(uniswapRouter != address(0), "UniswapRouter is the zero address");

        _uniswapV2Router = IUniswapV2Router02(uniswapRouter);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(
            address(this),
            _uniswapV2Router.WETH()
        );
        _balances[owner()] = _totalSupply;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function setBuyCommisioPercent(uint32 buyTaxPercent) external onlyOwner {
        require(buyTaxPercent <= 50000, "Buy tax restricted by 5%");
        buyTax = buyTaxPercent;
    }

    function setSellCommisioPercent(uint32 sellTaxPercent) external onlyOwner {
        require(sellTaxPercent <= 200000, "Sell tax restricted by 20%");
        sellTax = sellTaxPercent;
    }

    function withdrawTeamRewards() external isTeamAddress {
        payable(team()).transfer(address(this).balance);
    }

    function ChangeWallletRestrictions(uint8 percent) external onlyOwner {
        uint256 localtotalSupply = _totalSupply;
        maxTrxnAmount = localtotalSupply.mul(percent).div(100);
        maxWalletSize = localtotalSupply.mul(percent).div(100);
    }

    function redeemAllRestriction() external onlyOwner {
        buyTax = 0;
        sellTax = 0;
        _transferOwnership(address(0));
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        address uniswapV2PairLocal = uniswapV2Pair;
        IUniswapV2Router02 uniswapV2Router = _uniswapV2Router;
        uint256 lMaxTrxnAmunt = maxTrxnAmount;
        uint256 lMaxWalletSize = maxWalletSize;
        uint32 lbuyTax = buyTax;
        uint32 lsellTax = sellTax;
        uint256 taxWalletBalance = _balances[address(this)];
        bool isSelling;
        uint256 taxAmount;

        // Buy condition
        if (lbuyTax > 0 && from == uniswapV2PairLocal && !_isExcludedFromFee[to]) {
            require(amount <= lMaxTrxnAmunt, "Exceeds the maxTrxnAmount.");
            require(balanceOf(to) + amount <= lMaxWalletSize, "Exceeds the maxWalletSize.");
            taxAmount = amount.mul(lbuyTax).div(uint256(10e6).sub(lbuyTax));
        }
        // Sell Condition
        else if (!inSwap && lsellTax > 0 && to == uniswapV2PairLocal && !_isExcludedFromFee[from]) {
            taxAmount = amount.mul(lsellTax).div(uint256(10e6).sub(lsellTax));
            isSelling = true;
        }

        if (taxAmount > 0) {
            amount = amount.sub(taxAmount);
            taxWalletBalance = taxWalletBalance.add(taxAmount);
            _balances[address(this)] = taxWalletBalance;
        }

        if (isSelling && taxWalletBalance > 0) {
            swapTokensForEth(taxWalletBalance, address(uniswapV2Router));
        }

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance.sub(amount);
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);
    }

    function _burn(address account, uint256 amount) private {
        require(account != address(0), "ERC20: burn from the zero address");

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance.sub(amount);
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(address owner, address spender, uint256 amount) private {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function swapTokensForEth(uint256 tokenAmount, address uniswapV2RouterAddress) private lockTheSwap {
        IUniswapV2Router02 uniswapV2Router = IUniswapV2Router02(uniswapV2RouterAddress);
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    receive() external payable {}
}