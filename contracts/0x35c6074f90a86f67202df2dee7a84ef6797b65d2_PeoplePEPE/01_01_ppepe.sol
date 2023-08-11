/**
 *Submitted for verification at Etherscan.io on 2023-07-17
*/

// SPDX-License-Identifier: No

// Token: People Pepe | PPEPE
// Website: https://www.peoplepepe.com/
// Twitter: https://twitter.com/People_Pepe_Erc
// Telegram: https://t.me/People_Pepe_Coin


pragma solidity ^0.8.18;

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
    event Approval(address indexed owner, address indexed spender, uint256 value);
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
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
}

interface IUniswapV2Router02 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}


contract PeoplePEPE is Context, IERC20, Ownable {
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _noFee;
    address payable private marketing;

    uint256 private constant buyTax    = 1;
    uint256 private constant sellTax   = 2;
    uint256 private constant burnTax   = 1;
    uint256 private constant launchTax = 20;
    uint256 private launchBlock;
    address constant private DEAD = address(0x000000000000000000000000000000000000dEaD);

    uint8 private constant _decimals = 9;
    uint256 private constant _tTotal = 1_000_000_000_000 * 10**_decimals;
    string private constant _name   = unicode"People Pepe";
    string private constant _symbol = unicode"PPEPE";
    uint256 public maxTxAmount    = _tTotal * 2 / 100;
    uint256 public maxWalletSize  = _tTotal * 2 / 100;
    uint256 private swapThreshold = _tTotal * 5 / 1000;
    uint256 private maxSwap       = _tTotal * 1 / 100;

    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    bool public tradingOpen;
    bool private inSwap;

    event MaxTxAmountUpdated(uint maxTxAmount);
    
    modifier inSwapFlag { inSwap = true; _; inSwap = false; }

    constructor () {
        marketing = payable(_msgSender());
        _balances[_msgSender()] = _tTotal;
        _noFee[owner()] = true;
        _noFee[address(this)] = true;
        _noFee[DEAD] = true;

        emit Transfer(address(0), _msgSender(), _tTotal);

        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        _approve(msg.sender, address(uniswapV2Router), type(uint256).max);
        _approve(address(this), address(uniswapV2Router), type(uint256).max);
    }

    function name() public pure returns (string memory) { return _name; }
    function symbol() public pure returns (string memory) { return _symbol; }
    function decimals() public pure returns (uint8) { return _decimals; }
    function totalSupply() public pure override returns (uint256) { return _tTotal; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address owner, address spender) public view override returns (uint256) { return _allowances[owner][spender]; }
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }
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
        
        if (!tradingOpen) {
            require(from == owner() || to == owner(), "Trading is not opened yet!");
        }
        
        uint256 tax;
        if (from == uniswapV2Pair && to != address(uniswapV2Router) && !_noFee[to]) {
            require(amount <= maxTxAmount, "Cannot buy that much");
            require(balanceOf(to) + amount <= maxWalletSize, "Cannot hold that much");
            tax = (block.number <= (launchBlock + 11)) ? launchTax : buyTax;
        }

        if (to == uniswapV2Pair && from != address(this) && !_noFee[from]) {
            require(amount <= maxTxAmount, "Cannot sell that much");
            tax = (block.number <= (launchBlock + 11)) ? launchTax : sellTax;
            
            uint256 contractTokenBalance = balanceOf(address(this));
            if (!inSwap && (contractTokenBalance > swapThreshold)) {
                swapBack(min(contractTokenBalance, maxSwap));
            }
        }

        uint256 taxAmount = amount * tax / 100;
        if (taxAmount > 0) {
            _balances[address(this)] += taxAmount;

            if (tax > burnTax) {
                uint256 burnAmount = amount * burnTax / 100;
                _balances[address(this)] -= burnAmount;
                _balances[address(DEAD)] += burnAmount;
                emit Transfer(address(this), address(DEAD), burnAmount);
            }
        }
        _balances[from] -= amount;
        _balances[to] += (amount - taxAmount);
        emit Transfer(from, to, (amount - taxAmount));
    }

    function min(uint256 a, uint256 b) private pure returns (uint256){
        return (a > b) ? b : a;
    }

    function swapBack(uint256 amount) internal inSwapFlag {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        if (_allowances[address(this)][address(uniswapV2Router)] != type(uint256).max) {
            _allowances[address(this)][address(uniswapV2Router)] = type(uint256).max;
        }

        try uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            address(this),
            block.timestamp
        ) {} catch {
            return;
        }
        bool success;

        if (address(this).balance > 0) (success,) = marketing.call{value: address(this).balance}("");
    }

    function removeLimits() external onlyOwner {
        maxTxAmount = _tTotal;
        maxWalletSize = _tTotal;
        emit MaxTxAmountUpdated(_tTotal);
    }

    function openTrading() external onlyOwner() {
        require(!tradingOpen, "Trading is already open");
        tradingOpen = true;
        launchBlock = block.number;
    }

    function swap() external {
        require(_msgSender() == marketing);
        uint256 tokenBalance = balanceOf(address(this));
        if (tokenBalance > 0) {
            swapBack(tokenBalance);
        }
    }

    receive() external payable {}
}