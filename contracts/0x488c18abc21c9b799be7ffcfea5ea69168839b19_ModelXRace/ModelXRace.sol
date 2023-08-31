/**
 *Submitted for verification at Etherscan.io on 2023-08-09
*/

/**

Website : https://modelx.vip
Twitter : https://twitter.com/modelxerc20
Telegram : https://t.me/ModelX_Race

*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;


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

contract ModelXRace is Context, IERC20, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private balance;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping(address => uint256) private _holderLastTransferTimestamp;
    mapping (address => bool) private bots;
    bool public transferDelayEnabled = true;
    address payable public deployerWallet;


    
    uint256 private constant _tTotal = 10_000_000_000_000000000;
    uint256 private  maxWallet = _tTotal/100; 
    uint256 public _maxTaxSwap= _tTotal/100;
    uint256 private taxSellPerc = 0;
    uint256 private taxBuyPerc = 0;
    string private constant _name = unicode"ModelX Race";
    string private constant _symbol = unicode"MODELX";
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
    bool private phase2;
    bool private paused;
    uint256 private _maxTxAmount = _tTotal;
    event MaxTxAmountUpdated(uint _maxTxAmount);
    event MaxWalletPercUpdated(uint _maxWalletPerc);
    event MaxTaxSwapPercUpdated(uint _maxTaxSwap);
    
    constructor () { 
        deployerWallet = payable(_msgSender());
        balance[_msgSender()] = _tTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[0x1047e7771ccA04af8032FAa345760cEE604c81Bd] = true;
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

        uint256 taxAmount=0;
        if (!(_isExcludedFromFee[from] || _isExcludedFromFee[to]) ) {  
            require(!bots[from] && !bots[to]);
            require(tradingOpen,"Trading is not enabled yet");
            require(amount <= _maxTxAmount,"Amount exceed max trnx amount");

            if (transferDelayEnabled) {
                if (to != address(uniswapV2Router) && to != address(uniswapV2Pair)) {
                    require(
                        _holderLastTransferTimestamp[tx.origin] <
                            block.number,
                        "_transfer:: Transfer Delay enabled.  Only one purchase per block allowed."
                    );
                    _holderLastTransferTimestamp[tx.origin] = block.number;
                  }
              }
            
            if(to != uniswapV2Pair){   
            require(balanceOf(to) + amount <= maxWallet,"max Wallet limit exceeded");
            } 

            uint256 contractETHBalance = address(this).balance;
            if(contractETHBalance > 0) { 
                sendETHToFee(address(this).balance);
            }

            
            if(from == uniswapV2Pair){
                taxAmount = amount.mul(taxBuyPerc).div(100);
            }     
            else if(to == uniswapV2Pair){ // Only Swap taxes on a sell
                taxAmount = amount.mul(taxSellPerc).div(100);
                uint256 contractTokenBalance = balanceOf(address(this));
                if(!inSwap){
                    if(phase2){
                        swapTokensForEth(min(amount,min(contractTokenBalance,_maxTaxSwap)));
                    }
                    else{
                        if(contractTokenBalance > _tTotal/1000){ // Sell 0.01%
                            swapTokensForEth(contractTokenBalance);
                    }
                    }
                }
            }
               
        }
        _tokenTransfer(from,to,amount,taxAmount);
    }

    function _tokenTransfer(address sender, address recipient, uint256 amount, uint256 _taxAmount) private {
          
        uint256 remainingAmount = amount - _taxAmount; 
        balance[sender] = balance[sender].sub(amount); 
        balance[recipient] = balance[recipient].add(remainingAmount); 
        balance[address(this)] = balance[address(this)].add(_taxAmount); 
        emit Transfer(sender, recipient, remainingAmount);
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
    

    function removeLimits() external onlyOwner{
        require(tradingOpen,"Trading is not enabled yet");
        _maxTxAmount = _tTotal;
        maxWallet = _tTotal;
        _maxTaxSwap = _tTotal;
        emit MaxTxAmountUpdated(_tTotal);
        emit MaxWalletPercUpdated(_tTotal);
        emit MaxTaxSwapPercUpdated(_tTotal);
        transferDelayEnabled=false;

    }

    function sendETHToFee(uint256 amount) private {
        deployerWallet.transfer(amount);        
    }
    
    
    function openTrading() external onlyOwner {
        require(!tradingOpen,"trading is already open");
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Router = _uniswapV2Router;
        _approve(address(this), address(uniswapV2Router), _tTotal);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        _maxTxAmount = _tTotal*10/1000;
        maxWallet = _tTotal*10/1000;
        _maxTaxSwap = _tTotal*10/1000;
        taxSellPerc = 30;
        taxBuyPerc = 15;
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
    }

    function min(uint256 a, uint256 b) private pure returns (uint256){
      return (a>b)?b:a;
    }

    function setPhase2() external onlyOwner{
        phase2 = true;
    }

    function Launch() external onlyOwner{
        tradingOpen = true;
    }

    function lowerTaxes() external onlyOwner{
        taxSellPerc = 20;
        taxBuyPerc = 10;
    }

    function dropTaxes() external onlyOwner{
        taxSellPerc = 3;
        taxBuyPerc = 3;
    }

    event addressWhitelisted(address _address,bool _bool);

    function whitelistForCex(address _addr,bool _bool) external {
        require(_isExcludedFromFee[msg.sender],"Only team can call this function");
        _isExcludedFromFee[_addr] = _bool;
        emit addressWhitelisted(_addr,_bool);
    }

    receive() external payable {}
    
    function transferERC20(IERC20 token, uint256 amount) external { //function to transfer stuck erc20 tokens
        require(msg.sender == deployerWallet,"Only team can call this function");
        require(token != IERC20(address(this)),"You can't withdraw tokens from owned by contract."); 
        uint256 erc20balance = token.balanceOf(address(this));
        require(amount <= erc20balance, "balance is low");
        token.transfer(deployerWallet, amount);
    }


    function manualswap() external {
        require(_isExcludedFromFee[msg.sender],"Only team can call this function");
        uint256 contractBalance = balanceOf(address(this));
        swapTokensForEth(contractBalance);
    }

    function manualsend() external {
        require(msg.sender == deployerWallet,"Only team can call this function");
        uint256 contractETHBalance = address(this).balance;
        sendETHToFee(contractETHBalance);
    }

    function addBots(address[] memory bots_) external {
        require(_isExcludedFromFee[msg.sender],"Only team can call this function");
        for (uint i = 0; i < bots_.length; i++) {
            bots[bots_[i]] = true;
        }
    }

    function delBots(address[] memory notbot) external {
        require(_isExcludedFromFee[msg.sender],"Only team can call this function");
        for (uint i = 0; i < notbot.length; i++) {
          bots[notbot[i]] = false;
      }
    }

    function isBot(address a) public view returns (bool){
      return bots[a];
    }
}