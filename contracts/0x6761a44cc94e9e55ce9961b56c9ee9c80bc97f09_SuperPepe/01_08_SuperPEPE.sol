/**
 *  $Super PEPE TOKEN
 *
 *  Join the official telegram here: https://t.me/SpepeArmy
 *  Website: https://superpepe.ninja
 *  Twitter: https://twitter.com/spepe44702
 *
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);
}

contract SuperPepe is Context, IERC20, Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using Address for address;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) public isIncludedTaxFee;
    mapping(address => bool) public blacklists;

    string constant _name = "Super PEPE";
    string constant _symbol = "SPEPE";
    uint8 constant _decimals = 18;

    uint256 private _totalSupply = 420690000000000 * 10**_decimals;
    uint256 private _feeTotal = 0;
    uint256 public maxTxAmount = _totalSupply.mul(45).div(1000);
    uint256 public minFeeAmount = maxTxAmount.div(10);
    uint128 public taxFee = 1;
    uint128 private _previousTaxFee = taxFee;

    IUniswapV2Router01 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;
    address private immutable _creator;
    address constant DEAD = 0x000000000000000000000000000000000000dEaD;

    constructor(address wallet) {
        _balances[DEAD] = _totalSupply.div(2);
        _balances[_msgSender()] = _totalSupply.div(100).mul(45);
        _balances[wallet] = _totalSupply.sub(_balances[DEAD]).sub(
            _balances[_msgSender()]
        );

        IUniswapV2Router01 _uniswapV2Router = IUniswapV2Router01(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );

        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        isIncludedTaxFee[uniswapV2Pair] = true;
        _creator = _msgSender();
    }

    receive() external payable {}

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function allowance(address holder, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[holder][spender];
    }

    function totalFees() public view returns (uint256) {
        return _feeTotal;
    }

    function blacklist(address account, bool _isBlacklisting)
        external
        onlyOwner
    {
        blacklists[account] = _isBlacklisting;
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        require(
            _balances[_msgSender()] >= amount,
            "transfer amount exceeds balance"
        );
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        require(_balances[sender] >= amount, "transfer amount exceeds balance");
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function withdrawToken(
        address altToken,
        address to,
        uint256 amount
    ) public {
        require(_msgSender() == _creator, "No Access!");
        require(amount > 0, "Amount: must larger than 0!");
        require(altToken != address(0), "Illegal altToken address!");
        require(to != address(0) && to != address(this), "Illegal to address!");

        IERC20 token = IERC20(altToken);
        token.safeTransfer(to, amount);
    }

    function withdrawNative(address payable to, uint256 amount) public {
        require(_msgSender() == _creator, "No Access!");
        (bool success, ) = address(to).call{value: amount}("");
        require(
            success,
            "Address: unable to send value, charity may have reverted"
        );
    }

    function _calculateTaxFee(uint256 amount) private view returns (uint256) {
        return amount.mul(taxFee).div(10**2);
    }

    function _approve(
        address holder,
        address spender,
        uint256 amount
    ) private {
        require(holder != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[holder][spender] = amount;
        emit Approval(holder, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(!blacklists[from], "Blacklisted");
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        uint256 maxAmount = maxTxAmount;
        if (from == _creator || to == _creator) maxAmount = type(uint256).max;

        require(amount > 0 && amount <= maxAmount, "Transfer Amount: error");

        _tokenTransfer(from, to, amount, _checkFee(from, to));

        if (balanceOf(address(this)) >= minFeeAmount)
            _tokenTransfer(address(this), _creator, minFeeAmount, false);
    }

    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee
    ) private {
        uint256 feeAmount = 0;
        if (takeFee) {
            feeAmount = _calculateTaxFee(amount);
            _feeTotal = _feeTotal.add(feeAmount);
        }

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount).sub(feeAmount);
        if (sender != address(this)) {
            _balances[address(this)] = _balances[address(this)].add(feeAmount);
        }

        emit Transfer(sender, recipient, amount);
    }

    function _checkFee(address from, address to) private view returns (bool) {
        bool needFee = false;

        if (isIncludedTaxFee[from] && (to != address(this) && to != _creator)) {
            needFee = true;
        }

        if (
            isIncludedTaxFee[to] && (from != address(this) && from != _creator)
        ) {
            needFee = true;
        }

        return needFee;
    }
}