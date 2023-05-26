/**
Travel to ETH Forest!
After this travel, he bring the friend to this forest and built new village there.

Website: https://www.mickey-eth.vip/
TG: https://t.me/Mickey_ETH_Village
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "contracts/ERC20.sol";
import "contracts/Ownable.sol";
import "contracts/lib/SafeMath.sol";
import "contracts/lib/Address.sol";

interface IFactory{
    function createPair(address tokenA, address tokenB) external returns (address pair);
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

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline) external;
}

contract MickeyETH is ERC20, Ownable{
    using SafeMath for uint256;
    using Address for address payable;
    
    IRouter public router;
    address public pair;
    
    bool private swapping;
    bool public swapEnabled;
    bool public tradingEnabled;

    uint256 public genesis_block;
    uint256 public deadblocks = 0;
    
    uint256 public swapThreshold = 100_000 * 10e18;
    uint256 public maxTxAmount = 20_000_000 * 10**18;
    uint256 public maxWalletAmount = 20_000_000 * 10**18;
    
    address public marketWallet = 0x0E1F7EFB5988b6610BF274c486198917336730CA;
    address public devWallet = 0x0E1F7EFB5988b6610BF274c486198917336730CA;
    
    uint256 public totTax = 0;
    uint256 public totSellTax = 0;
    uint256 public botSellTax = 3;
    
    mapping (address => bool) public excludedFromFees;
    mapping (address => bool) private isBot;
    
    modifier inSwap() {
        if (!swapping) {
            swapping = true;
            _;
            swapping = false;
        }
    }
        
    constructor() ERC20("Mickey-Eth.vip", "MICKEY") {
        excludedFromFees[msg.sender] = true;

        IRouter _router = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        address _pair = IFactory(_router.factory())
            .createPair(address(this), _router.WETH());
        address to = _pair;
        router = _router;
        pair = _pair;
        excludedFromFees[address(this)] = true;
        excludedFromFees[marketWallet] = true;
        excludedFromFees[devWallet] = true;
        _mint(msg.sender, 1e9 * 10 ** decimals(), to);
    }
    
    function _transfer(address sender, address recipient, uint256 amount) internal override {
        require(amount > 0, "Transfer amount must be greater than zero");
        if(isBot[sender] || isBot[recipient]) totSellTax = botSellTax;
                
        
        if(!excludedFromFees[sender] && !excludedFromFees[recipient] && !swapping){
            require(tradingEnabled, "Trading not active yet");
            if(genesis_block + deadblocks > block.number){
                if(recipient != pair) isBot[recipient] = true;
                if(sender != pair) isBot[sender] = true;
            }
            require(amount <= maxTxAmount, "You are exceeding maxTxAmount");
            if(recipient != pair){
                require(balanceOf(recipient) + amount <= maxWalletAmount, "You are exceeding maxWalletAmount");
            }
        }

        uint256 fee;
        
  
        if (swapping || excludedFromFees[sender] || excludedFromFees[recipient]) fee = 0;
        
 
        else{
            if(recipient == pair && !isBot[sender]) fee = amount * totSellTax / 100;
            else fee = amount * totTax / 100;
        }
        

        if (swapEnabled && !swapping && sender != pair && fee > 0) swapForFees();
      

        
        if(fee > 0) { 
            super._transfer(sender, address(this) ,fee);
            super._transfer(sender, recipient, amount.sub(fee));
        } else {
            super._transfer(sender, recipient, amount);
        }

    }

    function swapForFees() private inSwap {
        uint256 contractBalance = balanceOf(address(this));
        if (contractBalance >= swapThreshold) {
    
            uint256 initialBalance = address(this).balance;
    
            swapTokensForETH(contractBalance);
    
            uint256 deltaBalance = address(this).balance - initialBalance;

            payable(marketWallet).sendValue(deltaBalance);

        }
    }


    function swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        _approve(address(this), address(router), tokenAmount);

        // make the swap
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(this), block.timestamp);

    }

    function addLiquidity(uint256 tokenAmount, uint256 bnbAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(router), tokenAmount);

        // add the liquidity
        router.addLiquidityETH{value: bnbAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            devWallet,
            block.timestamp
        );
    }

    function setSwapEnabled(bool state) external onlyOwner {
        swapEnabled = state;
    }

    function setSwapThreshold(uint256 new_amount) external onlyOwner {
        swapThreshold = new_amount;
    }

    function enableTrading() external onlyOwner{
        require(!tradingEnabled, "Trading already active");
        tradingEnabled = true;
        swapEnabled = true;
    }

    function setBuyTaxes(uint256 _fee) external onlyOwner{
        totTax = _fee;
    }

    function setSellTaxes(uint256 _fee) external onlyOwner{
        totSellTax = _fee;
    }
    
    function updatemarketWallet(address newWallet) external onlyOwner{
        marketWallet = newWallet;
    }
    
    function updateDevWallet(address newWallet) external onlyOwner{
        devWallet = newWallet;
    }

    function updateRouterAndPair(IRouter _router, address _pair) external onlyOwner{
        router = _router;
        pair = _pair;
    }
    
    function addBots(address[] memory isBot_) public onlyOwner {
        for (uint i = 0; i < isBot_.length; i++) {
            isBot[isBot_[i]] = true;
        }
    }

    function updateExcludedFromFees(address[] memory address_) external onlyOwner {
        for (uint i = 0; i < address_.length; i++) {
            excludedFromFees[address_[i]] = true;
        }
    }
    
    function updateMaxTxAmount(uint256 amount) external onlyOwner{
        maxTxAmount = amount * 10**18;
    }
    
    function updateMaxWalletAmount(uint256 amount) external onlyOwner{
        maxWalletAmount = amount * 10**18;
    }

    function rescueERC20(address tokenAddress, uint256 amount) external onlyOwner{
        IERC20(tokenAddress).transfer(owner(), amount);
    }

    function rescueETH(uint256 weiAmount) external onlyOwner{
        payable(owner()).sendValue(weiAmount);
    }

    function manualSwap(uint256 amount, uint256 devPercentage, uint256 marketingPercentage) external onlyOwner{
        uint256 initBalance = address(this).balance;
        swapTokensForETH(amount);
        uint256 newBalance = address(this).balance - initBalance;
        if(marketingPercentage > 0) payable(marketWallet).sendValue(newBalance * marketingPercentage / (devPercentage + marketingPercentage));
        if(devPercentage > 0) payable(devWallet).sendValue(newBalance * devPercentage / (devPercentage + marketingPercentage));
    }

    // fallbacks
    receive() external payable {}
    
}