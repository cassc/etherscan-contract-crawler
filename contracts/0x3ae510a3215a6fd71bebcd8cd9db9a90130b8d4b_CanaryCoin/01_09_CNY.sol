/**
 *Submitted for verification at Etherscan.io on 2023-09-28
*/

// SPDX-License-Identifier: MIT

/*
Because sometimes 'Production' is just another phrase for 'Our Largest Beta Test!' - Canary

Welcome to Canary - where a splash of humor meets a surge of innovation! 
Designed with a twinkle in our eyes and a robust roadmap in our hands, Canary is not your everyday meme Coin. 
It's a hilariously serious, technology-driven mechanism to pre-test our next big product. 
Canary Coin embodies our philosophy that there's nothing quite as thrilling - or informative - as testing in live production.

Backed by a myriad of robust features, our Coin doesn't just chirp; it sings tunes of progress, foresight, and unorthodox strategy. 
After all, if you're going to fail, why not fail fast, iterate faster, and have a hearty laugh along the way? 
The biggest production stage in the world is waiting for us - let's embrace the chaos with Canary!

Telegram: https://t.me/CanaryCoin

Features:
- Launch protection
- Base Buy/Sell tax: 5%
- MaxTx: 1%
- MaxWallet: 2%
- Enable/Disable Base tax (For marketing and promotions)
- RenounceOwnership

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@,,,,,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@,,,,,,,,,,,,,,,,,,,,,,,,,@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@@@@@@@@@@@@@@
@@@@@@@@@@@@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@@@@@@@@@@@
@@@@@@@@@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@@@@@@@@
@@@@@@@,,,,,,,,,,,,,,,,@@@@@@@@,,,,,,,,,,,,,,,,,,,,,,,,,,,@@@@@@
@@@@@,,,,,,,,,,,,,,@@@@@@@@@@@@@@@@,,,,,,,,,,,,,,,,,,,,,,,,,@@@@
@@@@,,,,,,,,,,,,@@@@@@@@@@@@,,,@@@@@#,,,,,,,,,,,,,,,,,,,,,,,,@@@
@@@,,,,,,,,,,,@@@@@@@@@@@@@@,,,@@@@@@@,,,,,,,,,,,,,,,,,,,,,,,,@@
@@,,,,,,,,,,,@@@@@@@@@@@@@@@@@@@@@@@@@@@@,,,,,,,,,,,,,,,,,,,,,,@
@,,,,,,,,,,,@@@@@@@@@@@@@@@@@@@@@@@@@/,,,,,,,,,,,,,,,,,,,,,,,,,,
@,,,,,,,,,,@@@@@@@@@@@@@@@@@@@@@@@@@@,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,@@@@@@@@@@@@@@@@@@@@@@@@@@@,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@,,,,,,,,,,,,,,,,,,,,,,,
@,,,,,,,,,,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@,,,,,,,,,,,,,,,,,,,,,
@,,,,,,,,,,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@,,,,,,,,,,,,,,,,,,
@,,,,,,,,,,,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@,,,,,,,,,,,,,,,@
@@,,,,,,,,,,,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@,,,,,,,,,,,,@
@@@,,,,,,,,,,,,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@,,,,,,,,,@@
@@@@#,,,,,,,,,,,,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@,,,,@@@@
@@@@@@,,,,,,,,,,,,,,(@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@,,,,,,,,,,,,,,,,,(@@@@@@@@@@@@@,,,,,,@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@,,,,,,,,,,,,,,,,,,@@@@@@@@@@@@@@@@@@@@@@@
*/

pragma solidity 0.8.21;

//https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeMath.sol
//Imports all the mathematical functions required to midicate overflow and underflow errors.
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
//https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol
//Imports the totalSupply(), balanceOf(), transfer(), allowance(), approve() and transferFrom() functions.
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
//https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol
//Imports all the validating functions reguired for addresses
import "@openzeppelin/contracts/utils/Address.sol";
//https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol
//Imports the owner(), _checkOwner(), renounceOwnership() and transferOwnership() functions.
import "@openzeppelin/contracts/access/Ownable.sol";
//https://github.com/Uniswap/v2-core/blob/master/contracts/interfaces/IUniswapV2Factory.sol
//Imports the Uniswap Factory interface for Pair creation.
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
//https://github.com/Uniswap/v2-periphery/blob/master/contracts/interfaces/IUniswapV2Router02.sol
//Imports the Uniswap Router interface for Liquidity and Swapping.
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract CanaryCoin is IERC20, Ownable {
    
    using SafeMath for uint256;
    using Address for address;

    string private constant _name = "Canary";
    string private constant _symbol = "CNY";
    uint8 private constant _decimals = 18;
    
    mapping(address => uint256) internal _balances;
    mapping(address => mapping(address => uint256)) internal _allowances;
    mapping(address => bool) private isExcludedFromTax;
    mapping(address => uint256) private _holderLastTransferTimestamp;
    
    uint256 private constant _totalSupply = 1000000000*10**_decimals; 

    uint256 private _maxTxAmount = 10000000*10**_decimals; // 1%
    uint256 private _maxWalletSize = 20000000*10**_decimals; // 2%
    uint256 private _taxSwapThreshold = 10000000*10**_decimals;
    uint256 private _maxTaxSwap = 10000000*10**_decimals;
    
    uint256 private _swapThreshold = 20;
    uint256 public _buyTax = 5; // Base Tax 5%
    uint256 public _sellTax = 5; // Base Tax 5%
    uint256 public _launchBuyTax = 25; // launch Tax 25%
    uint256 public _launchSellTax = 25; // launch Tax 25%
    uint256 public _buyCount = 0;

    address payable public _taxWallet; 
    address public uniswapV2Pair;

    bool public tradingOpen = false;
    bool public taxEnabled = true;
    bool public swapEnabled = false;
    bool public transferDelayEnabled = true;
    bool private inSwap = false;
    
    event MaxTxAmountUpdated(uint _maxTxAmount);
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }
 
    IUniswapV2Router02 private uniswapV2Router;    
    
    constructor() payable  {
        require(msg.value >= 1 ether, "Minimum 1 ether is required");

        _taxWallet = payable(_msgSender()); //Tax wallet

        isExcludedFromTax[address(uniswapV2Router)] = true;
        isExcludedFromTax[address(uniswapV2Pair)] = true;
        isExcludedFromTax[_msgSender()] = true;
        isExcludedFromTax[address(this)] = true;
        isExcludedFromTax[_taxWallet] = true;  

        _balances[address(this)] = _totalSupply;   
        emit Transfer(address(0), address(this), _totalSupply);
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

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
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

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        uint256 tax = 0; 
        if(taxEnabled){
            //Only one purchase per block allowed.
            if (transferDelayEnabled) {
                  if (recipient != address(uniswapV2Router) && recipient != address(uniswapV2Pair)) {
                      require(_holderLastTransferTimestamp[tx.origin] < block.number, "_transfer: Transfer Delay enabled. Only one purchase per block allowed.");
                      _holderLastTransferTimestamp[tx.origin] = block.number;
                  }
              }

            //Buy.
            if (sender == uniswapV2Pair && recipient != address(uniswapV2Router) && !isExcludedFromTax[recipient]) {
                    require(amount <= _maxTxAmount, "Exceeds the maxTxAmount.");
                    require(balanceOf(recipient) + amount <= _maxWalletSize, "Exceeds the maxWalletSize.");
                    tax = amount.mul((_buyCount > _swapThreshold) ? _buyTax : _launchBuyTax).div(100);
                    _buyCount++;
                }

            //Sell.
            if(recipient == uniswapV2Pair && sender != address(this) && !isExcludedFromTax[sender]) {
                    require(amount <= _maxTxAmount, "Exceeds the maxTxAmount.");
                    tax = amount.mul((_buyCount > _swapThreshold) ? _sellTax : _launchSellTax).div(100);
                }

            uint256 contractTokenBalance = balanceOf(address(this));
            if (!inSwap && recipient == uniswapV2Pair && swapEnabled && contractTokenBalance > _taxSwapThreshold && _buyCount > _swapThreshold) {
                    swapTokensForEth(min(amount,min(contractTokenBalance,_maxTaxSwap)));
                    uint256 contractETHBalance = address(this).balance;
                    if(contractETHBalance > 0) {
                        sendETHToTax(address(this).balance);
                    }
                }    
            }

            //Tax handover.
            if (tax > 0) {
                _balances[address(this)] = _balances[address(this)].add(tax);
                emit Transfer(sender, address(this), tax);
            }
        
        //Commit transaction.
        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount.sub(tax));
        emit Transfer(sender, recipient, amount.sub(tax));
    }

    //Returns the smaller of the two values.
    function min(uint256 a, uint256 b) private pure returns (uint256){
      return (a > b) ? b : a;
    }
    
    //Will open the trading and fill LP.
    function openTrading() external onlyOwner() {
        require(!tradingOpen,"trading is already open");
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        _approve(address(this), address(uniswapV2Router), _totalSupply);
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
        swapEnabled = true;
        tradingOpen = true;
    }

    //Makes sure contract can receive funds.
    receive() external payable {}
    
    //Enables base tax on transactions.
    function taxEnable() public onlyOwner {
        require(!taxEnabled,"tax is already enabled");
        taxEnabled = true;
    }

    //Disables base tax on transactions, used for marketing and promotions.
    function taxDisable() public onlyOwner {
        require(taxEnabled,"tax is already disabled");
        taxEnabled = false;
    }

    //Enables taxes for specified address.
    function IncludeInTax(address wallet, bool) public onlyOwner {
        isExcludedFromTax[wallet] = false;
    }

    //Disbles taxes for specified address.
    function ExcludedFromTax(address wallet, bool) public onlyOwner {
        isExcludedFromTax[wallet] = true;
    }

    //Send ETH to Tax.
    function sendETHToTax(uint256 amount) private {
        _taxWallet.transfer(amount);
    }

    //Swaps tokens for ETH.
    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        require(tradingOpen, "trading is not yet open");
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

    //Removes limits of maxTx and maxWallet
    function removeLimits() external onlyOwner{
        _maxTxAmount = _totalSupply;
        _maxWalletSize = _totalSupply;
        transferDelayEnabled = false;
        emit MaxTxAmountUpdated(_totalSupply);
    }

    //Manually swap tokens for ETH.
    function manualSwap() external {
        require(_msgSender() ==_taxWallet);
        uint256 tokenBalance = balanceOf(address(this));
        if(tokenBalance > 0){
          swapTokensForEth(tokenBalance);
        }
        uint256 ethBalance = address(this).balance;
        if(ethBalance > 0){
          sendETHToTax(ethBalance);
        }
    }
}