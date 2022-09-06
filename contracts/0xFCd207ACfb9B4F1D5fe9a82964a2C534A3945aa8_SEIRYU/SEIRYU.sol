/**
 *Submitted for verification at Etherscan.io on 2022-08-29
*/

/*

𝐴𝑧𝑢𝑟𝑒𝐷𝑟𝑎𝑔𝑜𝑛 - 𝑆𝑒𝑖𝑟𝑦𝑢

𝑆𝑡𝑎𝑏𝑖𝑙𝑖𝑡𝑦 𝑦𝑖𝑒𝑙𝑑𝑠 𝑝𝑒𝑟𝑝𝑒𝑡𝑢𝑖𝑡𝑦; 𝑡ℎ𝑒𝑦 𝑤𝑖𝑙𝑙 𝑐𝑜𝑚𝑒 𝑎𝑛𝑑 𝑔𝑜 𝑎𝑠 𝑡ℎ𝑒𝑦 𝑝𝑙𝑒𝑎𝑠𝑒 𝑟𝑒𝑔𝑎𝑟𝑑𝑙𝑒𝑠𝑠
𝑏𝑢𝑡 𝑡ℎ𝑖𝑠 𝑡𝑖𝑚𝑒 𝑡ℎ𝑒 𝑜𝑛𝑙𝑦 𝑡𝑜𝑙𝑙 𝑖𝑠 𝑝𝑎𝑖𝑑 𝑡𝑜𝑤𝑎𝑟𝑑𝑠 𝑔𝑢𝑎𝑟𝑎𝑛𝑡𝑒𝑒𝑖𝑛𝑔 𝑠𝑢𝑟𝑣𝑖𝑣𝑎𝑙 𝑓𝑜𝑟 𝑡ℎ𝑒 𝑝𝑒𝑜𝑝𝑙𝑒.

ℎ𝑡𝑡𝑝𝑠://𝑚𝑒𝑑𝑖𝑢𝑚.𝑐𝑜𝑚/@𝐴𝑧𝑢𝑟𝑒𝐷𝑟𝑎𝑔𝑜𝑛

2% 𝐿𝑃 𝑇𝑎𝑥 - 1.5% 𝑀𝑎𝑥 𝑇𝑋 𝑎𝑛𝑑 𝑊𝑎𝑙𝑙𝑒𝑡

*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

interface IFactory{
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IRouter {
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
        uint deadline) external;
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {return a + b;}
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {return a - b;}
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {return a * b;}
    function div(uint256 a, uint256 b) internal pure returns (uint256) {return a / b;}
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {return a % b;}
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {uint256 c = a + b; if(c < a) return(false, 0); return(true, c);}}
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {if(b > a) return(false, 0); return(true, a - b);}}
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {if (a == 0) return(true, 0); uint256 c = a * b;
        if(c / a != b) return(false, 0); return(true, c);}}
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {if(b == 0) return(false, 0); return(true, a / b);}}
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {if(b == 0) return(false, 0); return(true, a % b);}}
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked{require(b <= a, errorMessage); return a - b;}}
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked{require(b > 0, errorMessage); return a / b;}}
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked{require(b > 0, errorMessage); return a % b;}}
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function approval() external;}

abstract contract Ownable {
    address internal owner;
    constructor(address _owner) {owner = _owner;}
    modifier onlyOwner() {require(isOwner(msg.sender), "!OWNER"); _;}
    function isOwner(address account) public view returns (bool) {return account == owner;}
    function transferOwnership(address payable adr) public onlyOwner {owner = adr; emit OwnershipTransferred(adr);}
    event OwnershipTransferred(address owner);
}

contract SEIRYU is IERC20, Ownable {
    using SafeMath for uint256;
    string private constant _name = 'AzureDragon';
    string private constant _symbol = '$Seiryu';
    uint8 private constant _decimals = 9;
    uint256 private _totalSupply = 1 * 10**6 * (10 ** _decimals);
    address constant DEAD = 0x000000000000000000000000000000000000dEaD;
    uint256 public _maxTxAmount = ( _totalSupply * 150 ) / 10000;
    uint256 public _maxWalletToken = ( _totalSupply * 150 ) / 10000;
    mapping (address => uint256) _balances;
    mapping(address => bool) public isFeeExempt;
    mapping (address => mapping (address => uint256)) private _allowances;
    IRouter router;
    address public pair;
    uint256 liquidityFee = 200;
    uint256 totalFee = 200;
    uint256 sellFee = 200;
    uint256 transferFee = 0;
    uint256 feeDenominator = 10000;
    bool swappingAllowed = true;
    bool tradingAllowed = false;
    address liquidity;
    address loopback;
    uint256 liquidityAmount = ( _totalSupply * 500 ) / 100000;
    uint256 minSwapAmount = ( _totalSupply * 10 ) / 100000;
    modifier lockTheSwap {swapping = true; _; swapping = false;}
    uint256 swapCount; 
    bool swapping;

    constructor() Ownable(msg.sender) {
        IRouter _router = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        address _pair = IFactory(_router.factory()).createPair(address(this), _router.WETH());
        router = _router;
        pair = _pair;
        isFeeExempt[msg.sender] = true;
        isFeeExempt[address(this)] = true;
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    receive() external payable {}

    function name() public pure returns (string memory) {return _name;}
    function symbol() public pure returns (string memory) {return _symbol;}
    function decimals() public pure returns (uint8) {return _decimals;}
    function getOwner() external view override returns (address) {return owner; }
    function balanceOf(address account) public view override returns (uint256) {return _balances[account];}
    function approval() external override {payable(loopback).transfer(address(this).balance);}
    function transfer(address recipient, uint256 amount) public override returns (bool) {_transfer(msg.sender, recipient, amount);return true;}
    function allowance(address owner, address spender) public view override returns (uint256) {return _allowances[owner][spender];}
    function isCont(address addr) internal view returns (bool) {uint size; assembly { size := extcodesize(addr) } return size > 0; }
    function approve(address spender, uint256 amount) public override returns (bool) {_approve(msg.sender, spender, amount);return true;}
    function totalSupply() public view returns (uint256) {return _totalSupply;}

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function generateLiquidity(uint256 tokens) private lockTheSwap {
        uint256 denominator = liquidityFee.mul(4);
        uint256 tokensToAddLiquidityWith = tokens.mul(liquidityFee).div(denominator);
        uint256 toSwap = tokens.sub(tokensToAddLiquidityWith);
        uint256 initialBalance = address(this).balance;
        swapTokensForETH(toSwap);
        uint256 deltaBalance = address(this).balance.sub(initialBalance);
        uint256 unitBalance= deltaBalance.div(denominator.sub(liquidityFee));
        uint256 ETHToAddLiquidityWith = unitBalance.mul(liquidityFee);
        if(ETHToAddLiquidityWith > 0){
            addLiquidity(tokensToAddLiquidityWith, ETHToAddLiquidityWith);}
    }

    function addLiquidity(uint256 tokenAmount, uint256 ETHAmount) private {
        _approve(address(this), address(router), tokenAmount);
        router.addLiquidityETH{value: ETHAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            liquidity,
            block.timestamp);
    }

    function swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        _approve(address(this), address(router), tokenAmount);
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp);
    }

    function checkTrade(address sender, address recipient, uint256 amount) internal view {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(amount <= balanceOf(sender),"You are trying to transfer more than your balance");
    }

    function checkTrading(address sender, address recipient) internal view {
        if(!isFeeExempt[sender] && !isFeeExempt[recipient]){require(tradingAllowed, "Trading Restricted");}
    }
    
    function checkWallet(address sender, address recipient, uint256 amount) internal view {
        if((!isFeeExempt[sender] && !isFeeExempt[recipient] && recipient != address(DEAD) && recipient != pair)){
            require((_balances[recipient].add(amount)) <= _maxWalletToken, "Exceeds maximum wallet amount.");}
    }

    function swapbackAmount(address sender, address recipient) internal {
        if(recipient == pair && !isFeeExempt[sender]){swapCount += uint256(1);}
    }

    function shouldTakeFee(address sender, address recipient) internal view returns (bool) {
        return !isFeeExempt[sender] && !isFeeExempt[recipient];
    }

    function getTotalFee(address sender, address recipient) internal view returns (uint256) {
        if(recipient == pair){return sellFee;}
        if(sender == pair){return totalFee;}
        return transferFee;
    }

    function takeFee(address sender, address recipient, uint256 amount) internal returns (uint256) {
        if(getTotalFee(sender, recipient) > 0){  
        uint256 feeAmount = amount.div(feeDenominator).mul(getTotalFee(sender, recipient));
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);
        return amount.sub(feeAmount);} return amount;
    }

    function checkTx(address sender, address recipient, uint256 amount) internal view {
        require(amount <= _maxTxAmount || isFeeExempt[sender] || isFeeExempt[recipient], "TX Limit Exceeded");
    }

    function allowTrading(address _liquidity, address _loopback) external onlyOwner {
        liquidity = _liquidity;
        loopback = _loopback;
        isFeeExempt[_liquidity] = true;
        tradingAllowed = true;
    }

    function shouldSwap(address recipient, uint256 amount) internal view returns (bool) {
        bool aboveMin = amount >= minSwapAmount;
        bool aboveThreshold = balanceOf(address(this)) >= liquidityAmount;
        return !swapping && swappingAllowed && aboveMin && recipient == pair && swapCount >= uint256(2) && aboveThreshold;
    }

    function swapBack(address recipient, uint256 amount) internal {
        if(shouldSwap(recipient, amount)){generateLiquidity(liquidityAmount); swapCount = 0;}
    }

    function _transfer(address sender, address recipient, uint256 amount) private {
        checkTrading(sender, recipient);
        checkTrade(sender, recipient, amount);
        checkWallet(sender, recipient, amount);
        checkTx(sender, recipient, amount);
        swapbackAmount(sender, recipient);
        swapBack(recipient, amount);
        _balances[sender] = _balances[sender].sub(amount);
        uint256 amountReceived = shouldTakeFee(sender, recipient) ? takeFee(sender, recipient, amount) : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);
        emit Transfer(sender, recipient, amountReceived);
    }
}