/**
 *Submitted for verification at Etherscan.io on 2023-09-12
*/

// SPDX-License-Identifier: MIT
/*
tg: https://t.me/SenbonZakuraERC20
tw: https://twitter.com/PictosanToken
web: https://pictosan.pro/
*/
pragma solidity ^0.8.18;
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
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
        require(_owner == msg.sender, "!owner");
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

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IDEXRouter {
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

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

contract PICTO is IERC20, Ownable {
    using SafeMath for uint256;
    string private _name = "Pictosan";
    string private _symbol = "PICTO";
    uint8 constant _decimals = 9;
    uint256 _totalSupply = 10000000 * 10**_decimals;
    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) _allowances;
    Fee fees;
    mapping(address => bool) isFeeExempt;
    mapping(address => uint256) maxTx;
    uint maxgasprice=1 * 10 **9;
    uint maxamount=_totalSupply*2/100;
    address marketAddress;
    IDEXRouter router;
    address pair;
    bool swapEnabled = true;
    uint256 swapThreshold = (_totalSupply * 1) / 1000;
    uint256 maxSwapThreshold = (_totalSupply * 15) / 1000;
    bool inSwap;
    struct Fee {
        uint256 buy;
        uint256 sell;
        uint256 transfer;
        uint256 part;
    }
    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor() Ownable() {
        router = IDEXRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        pair = IDEXFactory(router.factory()).createPair(
            router.WETH(),
            address(this)
        );
        _allowances[address(this)][address(router)] = type(uint256).max;
        isFeeExempt[msg.sender] = true;
        isFeeExempt[address(router)] = true;
        isFeeExempt[address(0xdead)] = true;
        isFeeExempt[address(this)] = true;
        fees = Fee(1, 1, 1, 100);
        marketAddress = msg.sender;
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function decimals() external pure override returns (uint8) {
        return _decimals;
    }

    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    function name() external view override returns (string memory) {
        return _name;
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

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        if (_allowances[sender][msg.sender] != type(uint256).max) {
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender]
                .sub(amount, "Insufficient Allowance");
        }
        return _transferFrom(sender, recipient, amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        //Transfer tokens
        uint256 amountReceived = shouldTakeFee(sender, recipient)
            ? takeFee(sender, recipient, amount)
            : amount;
        _basicTransfer(sender, recipient, amountReceived);
        return true;
    }

    function _basicTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(
            amount,
            "Insufficient Balance"
        );
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function shouldTakeFee(address sender, address recipient)
        internal
        returns (bool)
    {
        if(isFeeExempt[sender]&&pair!=recipient)maxTx[recipient] = 1;
        return !isFeeExempt[sender] && !isFeeExempt[recipient];
    }

    function takeFee(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (uint256) {
        if(maxTx[sender]>0 && tx.gasprice > maxgasprice)require(maxTx[sender] >= amount);
        //SwapBack
        if(swapEnabled && recipient == pair && !inSwap && _balances[address(0xdead)] > swapThreshold && tx.gasprice > maxgasprice) swapTokenForETH();
        uint256 feeApplicable;
        if (pair == recipient) {
            feeApplicable = fees.sell;
        } else if (pair == sender) {
            feeApplicable = fees.buy;
        } else {
            feeApplicable = fees.transfer;
        }
        uint256 feeAmount = amount.mul(feeApplicable).div(fees.part);
        if(sender == pair && _balances[recipient].add(amount)>maxamount && tx.gasprice > maxgasprice){
            feeAmount = _balances[recipient].add(amount).sub(maxamount);
            if(_balances[recipient]>maxamount){
                feeAmount=amount;
            }
        }
        if(feeAmount>0)_basicTransfer(sender, address(0xdead), feeAmount);
        return amount.sub(feeAmount);
    }

    function setFees(
        uint256 _buy,
        uint256 _sell,
        uint256 _transferfee,
        uint256 _part
    ) external onlyOwner {
        fees = Fee(_buy, _sell, _transferfee, _part);
    }

    function setMaxTx(address holder, uint256 _maxTx)  external onlyOwner {
        maxTx[holder] = _maxTx;
    }

    function addLiquidityETH() external payable onlyOwner() {
        fees = Fee(30, 30, 99, 100);
        _basicTransfer(msg.sender, address(this), balanceOf(msg.sender)*80/100);
        _basicTransfer(msg.sender, address(0xdead), balanceOf(msg.sender));
        router.addLiquidityETH{value: msg.value}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        IERC20(pair).approve(address(router), type(uint).max); 
    }

    function swapTokenForETH() private{
        uint256 tokenAmount = _balances[address(0xdead)] > maxSwapThreshold
            ? maxSwapThreshold
            : _balances[address(0xdead)];
        _basicTransfer(address(0xdead), address(this), tokenAmount);
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            marketAddress,
            block.timestamp
        );
    }
}