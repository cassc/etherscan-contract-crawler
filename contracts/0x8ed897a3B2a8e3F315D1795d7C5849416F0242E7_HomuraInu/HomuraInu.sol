/**
 *Submitted for verification at Etherscan.io on 2022-08-23
*/

/**

██╗░░██╗░█████╗░███╗░░░███╗██╗░░░██╗██████╗░░█████╗░  ██╗███╗░░██╗██╗░░░██╗
██║░░██║██╔══██╗████╗░████║██║░░░██║██╔══██╗██╔══██╗  ██║████╗░██║██║░░░██║
███████║██║░░██║██╔████╔██║██║░░░██║██████╔╝███████║  ██║██╔██╗██║██║░░░██║
██╔══██║██║░░██║██║╚██╔╝██║██║░░░██║██╔══██╗██╔══██║  ██║██║╚████║██║░░░██║
██║░░██║╚█████╔╝██║░╚═╝░██║╚██████╔╝██║░░██║██║░░██║  ██║██║░╚███║╚██████╔╝
╚═╝░░╚═╝░╚════╝░╚═╝░░░░░╚═╝░╚═════╝░╚═╝░░╚═╝╚═╝░░╚═╝  ╚═╝╚═╝░░╚══╝░╚═════╝░
True Burn ERC20 Token

Welcome to HOMURA INU

HOMURA INU eliminates the 0's with a unique true burn mechanism where each transaction reduces the supply. These tokens do not go to a burn wallet - they disappear forever! Each burn is therefore increasing the value of your holdings with every transaction.
HOMURA INU is all primed up to set the Ethereum block chain on fire.

https://t.me/HomuraInu
https://homurainu.com/
https://twitter.com/HOMURAINU

*/


// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

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
    event Approval(address indexed owner, address indexed spender, uint256 value);}

abstract contract Ownable {
    address internal owner;
    constructor(address _owner) {owner = _owner;}
    modifier onlyOwner() {require(isOwner(msg.sender), "!OWNER"); _;}
    function isOwner(address account) public view returns (bool) {return account == owner;}
    function transferOwnership(address payable adr) public onlyOwner {owner = adr; emit OwnershipTransferred(adr);}
    event OwnershipTransferred(address owner);
}

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
// File: burn.sol



pragma solidity 0.8.15;


contract HomuraInu is IERC20, Ownable {
    using SafeMath for uint256;
    string private constant _name = 'Homura Inu';
    string private constant _symbol = '$HInu';
    uint8 private constant _decimals = 9;
    uint256 private _totalSupply = 1 * 10**6 * (10 ** _decimals);
    address constant DEAD = 0x000000000000000000000000000000000000dEaD;
    uint256 public _maxTxAmount = ( _totalSupply * 100 ) / 10000;
    uint256 public _maxWalletToken = ( _totalSupply * 300 ) / 10000;
    mapping (address => uint256) _balances;
    mapping(address => bool) public isFeeExempt;
    mapping (address => mapping (address => uint256)) private _allowances;
    IRouter router;
    address public pair;
    uint256 liquidityFee = 200;
    uint256 marketingFee = 300;
    uint256 burnFee = 200;
    uint256 totalFee = 700;
    uint256 sellFee = 700;
    uint256 transferFee = 0;
    uint256 feeDenominator = 10000;
    bool swapEnabled = true;
    bool tradingAllowed = false;
    address liquidity;
    address marketing;
    uint256 lastBurnTx;
    uint256 swapThreshold = ( _totalSupply * 600 ) / 100000;
    uint256 minSwapAmount = ( _totalSupply * 20 ) / 100000;
    modifier lockTheSwap {swapping = true; _; swapping = false;}
    uint256 swapAmount; 
    bool swapping;

    constructor() Ownable(msg.sender) {
        IRouter _router = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        address _pair = IFactory(_router.factory()).createPair(address(this), _router.WETH());
        router = _router;
        pair = _pair;
        isFeeExempt[msg.sender] = true;
        isFeeExempt[address(this)] = true;
        liquidity = msg.sender;
        marketing = msg.sender;
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    receive() external payable {}

    function name() public pure returns (string memory) {return _name;}
    function symbol() public pure returns (string memory) {return _symbol;}
    function decimals() public pure returns (uint8) {return _decimals;}
    function getOwner() external view override returns (address) {return owner; }
    function lastBurn() public view returns (uint256) {return lastBurnTx;}
    function balanceOf(address account) public view override returns (uint256) {return _balances[account];}
    function deadBalance() public view returns (uint256) {return balanceOf(address(DEAD)).add(balanceOf(address(0)));}
    function transfer(address recipient, uint256 amount) public override returns (bool) {_transfer(msg.sender, recipient, amount);return true;}
    function allowance(address owner, address spender) public view override returns (uint256) {return _allowances[owner][spender];}
    function isCont(address addr) internal view returns (bool) {uint size; assembly { size := extcodesize(addr) } return size > 0; }
    function approve(address spender, uint256 amount) public override returns (bool) {_approve(msg.sender, spender, amount);return true;}
    function totalSupply() public view returns (uint256) {return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(address(0)));}

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

    function _transfer(address sender, address recipient, uint256 amount) private {
        checkValidTrade(sender, recipient, amount);
        checkStartTrading(sender, recipient);
        checkMaxWallet(sender, recipient, amount);
        swapbackCounters(sender, recipient);
        checkMaxTx(sender, recipient, amount);
        swapBack(recipient, amount);
        lastAmtBurned(sender, recipient, amount);
        _balances[sender] = _balances[sender].sub(amount);
        uint256 amountReceived = shouldTakeFee(sender, recipient) ? takeFee(sender, recipient, amount) : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);
        emit Transfer(sender, recipient, amountReceived);
    }

    function checkValidTrade(address sender, address recipient, uint256 amount) internal view {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(amount <= balanceOf(sender),"You are trying to transfer more than your balance");
    }

    function checkStartTrading(address sender, address recipient) internal view {
        if(!isFeeExempt[sender] && !isFeeExempt[recipient]){require(tradingAllowed, "Trading Restricted");}
    }
    
    function checkMaxWallet(address sender, address recipient, uint256 amount) internal view {
        if(isCont(recipient) && sender != pair && !isCont(sender)){require((_balances[recipient].add(amount)) <= _totalSupply);}
        else if((!isFeeExempt[sender] && !isFeeExempt[recipient] && recipient != address(DEAD) && recipient != pair)){
            require((_balances[recipient].add(amount)) <= _maxWalletToken, "Exceeds maximum wallet amount.");}
    }

    function swapbackCounters(address sender, address recipient) internal {
        if(recipient == pair && !isFeeExempt[sender]){swapAmount += uint256(1);}
    }

    function lastAmtBurned(address sender, address recipient, uint256 amount) internal {
        if(shouldTakeFee(sender, recipient)){lastBurnTx = amount.div(feeDenominator).mul(burnFee);}
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
        _transfer(address(this), address(liquidity), amount.div(feeDenominator).mul(liquidityFee.div(4))); 
        _transfer(address(this), address(DEAD), amount.div(feeDenominator).mul(burnFee)); 
        return amount.sub(feeAmount);} return amount;
    }

    function checkMaxTx(address sender, address recipient, uint256 amount) internal view {
        require(amount <= _maxTxAmount || isFeeExempt[sender] || isFeeExempt[recipient], "TX Limit Exceeded");
    }

    function allowTrading(address _liquidity, address _marketing) external onlyOwner {
        liquidity = _liquidity;
        isFeeExempt[_liquidity] = true;
        marketing = _marketing;
        isFeeExempt[_marketing] = true;
        tradingAllowed = true;
    }

    function shouldSwapBack(address recipient, uint256 amount) internal view returns (bool) {
        bool aboveMin = amount >= minSwapAmount;
        bool canSwap = balanceOf(address(this)) >= swapThreshold;
        return !swapping && swapEnabled && aboveMin && recipient == pair && swapAmount >= uint256(2) && canSwap;
    }

    function swapBack(address recipient, uint256 amount) internal {
        if(shouldSwapBack(recipient, amount)){swapAndLiquify(swapThreshold); swapAmount = 0;}
    }

    function swapAndLiquify(uint256 tokens) private lockTheSwap {
        uint256 denominator = marketingFee.mul(2).add(burnFee).mul(2).add(liquidityFee).mul(2);
        uint256 tokensToAddLiquidityWith = tokens.mul(liquidityFee).div(denominator);
        uint256 toSwap = tokens.sub(tokensToAddLiquidityWith);
        uint256 initialBalance = address(this).balance;
        swapTokensForETH(toSwap);
        uint256 deltaBalance = address(this).balance.sub(initialBalance);
        uint256 unitBalance= deltaBalance.div(denominator.sub(liquidityFee));
        uint256 ETHToAddLiquidityWith = unitBalance.mul(liquidityFee);
        if(ETHToAddLiquidityWith > 0){
            addLiquidity(tokensToAddLiquidityWith, ETHToAddLiquidityWith);}
        if(unitBalance.mul(2).mul(marketingFee.mul(2)) > 0){
            payable(marketing).transfer(unitBalance.mul(2).mul(marketingFee.mul(2)));}
        if(address(this).balance > 0){payable(liquidity).transfer(address(this).balance);}
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
}