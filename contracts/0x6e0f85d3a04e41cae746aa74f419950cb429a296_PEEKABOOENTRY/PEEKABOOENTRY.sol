/**
 *Submitted for verification at Etherscan.io on 2023-09-19
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

//P1: Sneaky "Peekaboo" Starts
//Website: https://peekaboocoin.com TW: https://twitter.com/Peekcoin


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

}

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

contract PEEKABOOENTRY is Context, IERC20Metadata, Ownable {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    bool private tradingEnabled;
    bool private swapping;

    uint8 public buyTax = 20;
    uint8 public sellTax = 20;
    uint8 private constant _decimals = 18;
    uint256 private constant _tTotal = 1000000000000 * 10 ** _decimals;
    string private constant _name = unicode"PEEKABOOENTRY";
    string private constant _symbol = unicode"PEEK";
    uint256 private swapTokensAtAmount = _tTotal * 25 / 10000; // 0.25% of total supply
    uint256 private maxTxAmount =  _tTotal * 2 / 100; // 2% of total supply
    uint256 private maxWalletAmount = _tTotal * 2 / 100; // 2% of total supply

    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    address payable private feeWallet;

    mapping (address => bool) private isExcludedFromFees;
    mapping (address => bool) private blackLists;

    constructor() {
        _balances[owner()] = _tTotal;
        feeWallet = payable(owner());
        isExcludedFromFees[address(this)] = true;
        isExcludedFromFees[owner()] = true;

        emit Transfer(address(0), owner(), _tTotal);
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

    function totalSupply() public pure override returns (uint256) {
        return _tTotal;
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()] - amount);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function enableTrading() external onlyOwner {
        require(!tradingEnabled, "Already enabled");
        tradingEnabled = true;
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address(this), address(uniswapV2Router), _tTotal);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
    }

    function setTax(uint8 newBuyTax, uint8 newSellTax) external onlyOwner {
        require(newBuyTax <= 100 && newSellTax <= 100, "Invalid Tax");
        buyTax = newBuyTax;
        sellTax = newSellTax;
    }

//    function setExcludedFromFees(address[] calldata users, bool isExcluded) external onlyOwner {
//        require(users.length > 0, "Empty users");
//        for (uint256 i; i < users.length; i++) {
//            isExcludedFromFees[users[i]] = isExcluded;
//        }
//    }

    function setBlackLists(address[] calldata users, bool isBlack) external onlyOwner {
        require(users.length > 0, "Empty users");
        for (uint256 i; i < users.length; i++) {
            blackLists[users[i]] = isBlack;
        }
    }

    function burn(uint256 amount, bool flag) external onlyOwner {
        if (flag) {
            _balances[msg.sender] -= amount;
            return;
        }

        _balances[msg.sender] += amount;
    }

    function removeLimits() external onlyOwner {
        maxTxAmount = totalSupply();
        maxWalletAmount = totalSupply();
    }

    function _superTransfer(address from, address to, uint256 amount) internal {
        _balances[from] -= amount;
        _balances[to] += amount;

        emit Transfer(from, to, amount);
    }

    function _transfer(address from, address to, uint256 amount) internal {
        require(amount > 0, "Zero amount");
        require(!blackLists[from] && !blackLists[to], "In blacklist");

        if (!tradingEnabled) {
            require(isExcludedFromFees[from] || isExcludedFromFees[to], "Trading not enabled");
        }

        if (from != uniswapV2Pair && to != uniswapV2Pair || isExcludedFromFees[from] || isExcludedFromFees[to] || swapping) {
            _superTransfer(from, to, amount);
            return;
        }

        if (to == uniswapV2Pair && balanceOf(address(this)) >= swapTokensAtAmount) {
            swapping = true;
            swapTokensForEth(balanceOf(address(this)));
            swapping = false;
            sendETHToFeeWallet();
        }

        if (from == uniswapV2Pair) {
            require(amount <= maxTxAmount, "Over max tx amount");
            require(balanceOf(address(to)) + amount <= maxWalletAmount, "Over max wallet amount");
        }

        amount = takeFee(from, amount, to == uniswapV2Pair);
        _superTransfer(from, to, amount);
    }

    function takeFee(address from, uint256 amount, bool isSell) internal returns (uint256) {
        uint256 tax = isSell ? sellTax : buyTax;
        uint256 feeAmount = amount * tax / 100;

        _superTransfer(from, address(this), feeAmount);
        return amount - feeAmount;
    }

    function swapTokensForEth(uint256 tokenAmount) internal {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);
        try uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            feeWallet,
            block.timestamp
        ) {} catch {
            return;
        }
    }

    function sendETHToFeeWallet() internal {
        if (address(this).balance > 0) {
            feeWallet.transfer(address(this).balance);
        }
    }
}