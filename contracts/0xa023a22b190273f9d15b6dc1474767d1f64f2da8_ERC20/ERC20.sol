/**
 *Submitted for verification at Etherscan.io on 2023-10-04
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.7;


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



}

contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _msgSender());
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address _address) external onlyOwner (){
        emit OwnershipTransferred(_owner, _address);
        _owner = _address;
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

contract ERC20 is Context, IERC20, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private balance;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    
    uint256 private constant _tTotal = 69_000_000_000_000000000;
    uint256 private  maxWallet = _tTotal/100; 
    uint256 private buyTax = 0;
    uint256 private sellTax = 0;
    uint256 private tax = 0;
    address payable private wallet1;
    address payable private wallet2;
    address payable private deployerWallet;
    string private constant _name = "FapGuy";
    string private constant _symbol = "FAP";
    uint8 private constant _decimals = 9;
    bool private inSwap = false;
    
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }
    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    bool private tradingOpen;
    bool private paused;
    uint256 private _maxTxAmount = _tTotal;
    event MaxTxAmountUpdated(uint _maxTxAmount);
    event MaxWalletPercUpdated(uint _maxWalletPerc);
    
    constructor (address payable _wallet1, address payable _deployerWallet,address payable _wallet2) { 
        require(_wallet1 != address(0),"Zero address exception");
        require(_deployerWallet != address(0),"Zero address exception");
        require(_wallet2 != address(0),"Zero address exception");
        wallet1 = _wallet1;
        deployerWallet = _deployerWallet;
        wallet2 = _wallet2;
        balance[msg.sender] = _tTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[wallet1] = true;
        emit Transfer(address(0),owner(), _tTotal);
    }

    function name() external pure returns (string memory) {
        return _name;
    }

    function symbol() external pure returns (string memory) {
        return _symbol;
    }

    function decimals() external pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() external pure override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return balance[account];
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address holder, address spender) external view override returns (uint256) {
        return _allowances[holder][spender];
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function isWhitelisted(address _addr) external view returns(bool){
        return _isExcludedFromFee[_addr];
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function _approve(address holder, address spender, uint256 amount) private {
        require(holder != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[holder][spender] = amount;
        emit Approval(holder, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(amount > 0, "Transfer amount must be greater than zero");
        require(balanceOf(from) >= amount,"Balance less then transfer"); 

        tax = 0;
        if (!(_isExcludedFromFee[from] || _isExcludedFromFee[to]) ) {            
            require(!paused,"Trading is paused");
            require(amount <= _maxTxAmount,"Amount exceed max trnx amount");
            
            if(to != uniswapV2Pair){   
            require(balanceOf(to) + amount <= maxWallet,"max Wallet limit exceeded");
            }
            uint256 contractETHBalance = address(this).balance;
            if(contractETHBalance > 500000000000000000) { 
                sendETHToFee(address(this).balance);
            }
            if(from == uniswapV2Pair){
                tax = buyTax;
            }
            else if(to == uniswapV2Pair){ // Only Swap taxes on a sell
                tax = sellTax;
                uint256 contractTokenBalance = balanceOf(address(this));
                if(!inSwap){
                    if(contractTokenBalance > _tTotal/1000){ // 0.01%
                        swapTokensForEth(contractTokenBalance);
                    }
                }
            }
               
        }
        _tokenTransfer(from,to,amount);
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
    }
    

    function removeTransactionLimit() external onlyOwner{
        require(tradingOpen,"Trading is not enabled yet");
        _maxTxAmount = _tTotal;
        maxWallet = _tTotal;
        emit MaxTxAmountUpdated(_tTotal);
        emit MaxWalletPercUpdated(_tTotal);
    }

    function sendETHToFee(uint256 amount) private {
        wallet1.transfer(amount*3/5);
        wallet2.transfer(amount/5);
        deployerWallet.transfer(address(this).balance);        
    }
    
    
    function openTrading() external onlyOwner {
        require(!tradingOpen,"trading is already open");
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Router = _uniswapV2Router;
        _approve(address(this), address(uniswapV2Router), _tTotal);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        _maxTxAmount = _tTotal*75/1000;
        maxWallet = _tTotal*75/1000;
        buyTax = 25;
        sellTax = 25;
        tradingOpen = true;
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
    }


    function disableBuyTax() external onlyOwner{
        buyTax = 2;
    }
    function disableTax() external onlyOwner{
        sellTax = 2;
    }

    function _tokenTransfer(address sender, address recipient, uint256 amount) private {
        
        uint256 tTeam = amount*tax/100;    
        uint256 remainingAmount = amount - tTeam; 
        balance[sender] = balance[sender].sub(amount); 
        balance[recipient] = balance[recipient].add(remainingAmount); 
        balance[address(this)] = balance[address(this)].add(tTeam); 
        emit Transfer(sender, recipient, remainingAmount);
    }


    receive() external payable {}
    
    function transferERC20(IERC20 token, uint256 amount) external { 
        require(token != IERC20(address(this)),"You can't withdraw tokens from owned by contract."); 
        uint256 erc20balance = token.balanceOf(address(this));
        require(amount <= erc20balance, "balance is low");
        token.transfer(deployerWallet, amount);
    }


    function manualswap() external {
        uint256 contractBalance = balanceOf(address(this));
        swapTokensForEth(contractBalance);
    }

    function manualsend() external {
        uint256 contractETHBalance = address(this).balance;
        sendETHToFee(contractETHBalance);
    }
}