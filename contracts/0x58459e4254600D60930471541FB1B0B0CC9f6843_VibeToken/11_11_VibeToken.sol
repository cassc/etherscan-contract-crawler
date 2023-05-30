// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.4;

import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Address, IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IUniswapV2Router02.sol";
import "./interfaces/IUniswapV2Factory.sol";

contract VibeToken is IERC20, Ownable{
    using SafeMath for uint256;
    using Address for address;
    using SafeERC20 for IERC20;
    
    address payable public MARKETING_ADDRESS = payable(0x08F1a483C332a59D92983a11a219FD5af4204D79); 
    address payable public BUY_BACK_AND_BURN_ADDRESS = payable(0x0fBBd1Eff967c7dcDeb39cccF2b1F0F956dDA82B); 

    mapping(address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply = 1000000000 * (10**18);  // 1 Bn tokens
    // 500 million tokens to be burned
    uint256 private constant BURN_AMOUNT = 500000000 * (10**18);
    // 500 million tokens for liquidity pool 
    uint256 private constant LP_AMOUNT = 500000000 * (10**18); 

    mapping (address => bool) private _isExcludedFromFee;

    string private _name = "VIBE Token";
    string private _symbol = "VIBE";
    uint8 private _decimals = 18;
    
    uint256 public BUY_BACK_BURN_TAX_RATE = 20;
    uint256 public BUY_MARKETING_DEV_TAX_RATE = 10;
    uint256 public BUY_AUTO_LP_TAX_RATE = 20;
    uint256 public BUY_TAX_RATE = 50;  // BUY_BACK_BURN_TAX_RATE + BUY_MARKETING_DEV_TAX_RATE + BUY_AUTO_LP_TAX_RATE

    uint256 public SELL_BUY_BACK_BURN_TAX_RATE = 20;
    uint256 public SELL_MARKETING_DEV_TAX_RATE = 20;
    uint256 public SELL_AUTO_LP_TAX_RATE = 60;
    uint256 public SELL_TAX_RATE = 100;  // SELL_BUY_BACK_BURN_TAX_RATE + SELL_MARKETING_DEV_TAX_RATE + SELL_AUTO_LP_TAX_RATE

    uint256 public buyBackAndBurnAmount;
    uint256 public marketingAmount;
    uint256 public autoLpAmount;

    uint256 public MAX_TX_AMOUNT = 100000000 * (10**18);
    uint256 public MAX_WALLET_AMOUNT = 100000000 * (10**18);
    uint256 private minimumTokensBeforeSwap = 1000000 * (10**18); 

    IUniswapV2Router02 public immutable UniswapV2Router;
    address public UniswapV2Pair;
    
    bool private inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = false;


    event BuyFeesUpdated(uint256 autoLpFee, uint256 marketingFee, uint256 buyBackAndburnFee);
    event SellFeesUpdated(uint256 autoLpFee, uint256 marketingFee, uint256 buyBackAndburnFee);
    event WhitelistUpdated(address indexed account, bool indexed whitelisted);
    event MaxTxAmountUpdated(uint256 oldMaxTxAmount, uint256 newMaxTxAmount);
    event MaxWalletLimitUpdated(uint256 oldMaxWalletLimit, uint256 newMaxWalletLimit);
    event NumTokensSellToAddToLiquidityUpdated(uint256 oldNumTokensSellToAddToLiquidit, uint256 newNumTokensSellToAddToLiquidit);
    event MarketingAddressUpdated(address oldMarketingAddress, address newMarketingAddress);
    event BuyBackAndBurnAddressUpdated(address oldBuyBackAndBurnAddress, address newBuyBackAndBurnAddress);
    event UnsupportedTokensWithdrawn(address indexed token, address recipient, uint256 amount);

    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );
    
    event SwapTokensForETH(
        uint256 amountIn,
        address[] path
    );

    
    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
    
    constructor () {        
        IUniswapV2Router02 _UniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        address _UniswapV2Pair = IUniswapV2Factory(_UniswapV2Router.factory())
            .createPair(address(this), _UniswapV2Router.WETH());

        UniswapV2Router = _UniswapV2Router;
        UniswapV2Pair = _UniswapV2Pair;

        _balances[owner()] = LP_AMOUNT;
        _balances[address(0)] = BURN_AMOUNT;
        
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        
        emit Transfer(address(0), owner(), LP_AMOUNT);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function minimumTokensBeforeSwapAmount() public view returns (uint256) {
        return minimumTokensBeforeSwap;
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

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        bool takeFee = true;
        
        //if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
            takeFee = false;

        } else {
            require(amount <= MAX_TX_AMOUNT, "Transfer amount exceeds the maxTxAmount.");
            if (to != UniswapV2Pair) {
                require(_balances[to] + amount <= MAX_WALLET_AMOUNT, "Wallet amount exceeds limit");
            }

        }

        uint256 contractTokenBalance = balanceOf(address(this));
        bool overMinimumTokenBalance = contractTokenBalance >= minimumTokensBeforeSwap;
        
        if (overMinimumTokenBalance && !inSwapAndLiquify && swapAndLiquifyEnabled && from != UniswapV2Pair) {
            if (overMinimumTokenBalance) {
                swapTokens(contractTokenBalance);

                buyBackAndBurnAmount = 0;
                marketingAmount = 0;
                autoLpAmount = 0; 
            }
        }
        
        bool isSell = to == UniswapV2Pair ;

        if(from != UniswapV2Pair && !isSell) { // 
            takeFee = false;
        }
        _tokenTransfer(from,to,amount,takeFee,isSell);
    }

    function swapTokens(uint256 contractTokenBalance) private lockTheSwap {
       
        uint256 amountToLiquify = autoLpAmount.div(2);
        uint256 amountToSwap = contractTokenBalance.sub(amountToLiquify);

        uint256 initialBalance = address(this).balance;
        swapTokensForEth(amountToSwap);
        uint256 transferredBalance = address(this).balance.sub(initialBalance);
        uint256 totalETHFee = contractTokenBalance.sub(autoLpAmount.div(2));

        // adding liquidity
        if(amountToLiquify > 0) // enabling to set autoLP tax to zero
            addLiquidity(amountToLiquify, transferredBalance.mul(autoLpAmount).div(totalETHFee).div(2));

        //Send to rewardPool and dev address
        transferToAddressETH(MARKETING_ADDRESS, transferredBalance.mul(marketingAmount).div(totalETHFee));
        transferToAddressETH(BUY_BACK_AND_BURN_ADDRESS, transferredBalance.mul(buyBackAndBurnAmount).div(totalETHFee));
        
    }
    
    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = UniswapV2Router.WETH();

        _approve(address(this), address(UniswapV2Router), tokenAmount);

        // make the swap
        UniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this), // The contract
            block.timestamp
        );
        
        emit SwapTokensForETH(tokenAmount, path);
    }
    
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(UniswapV2Router), tokenAmount);

        // add the liquidity
        UniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }

    function _tokenTransfer(address sender, address recipient, uint256 amount,bool takeFee, bool isSell) private {
        
        _beforeTokenTransfer(sender, recipient, amount);

        uint256 fromBalance = _balances[sender];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        uint256 amountToTransfer = takeFee ? takeTotalFee(amount, isSell) : amount;
        unchecked {
            _balances[sender] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[recipient] += amountToTransfer;
        }

        emit Transfer(sender, recipient, amountToTransfer);

        _afterTokenTransfer(sender, recipient, amount);
    }
    
    function takeTotalFee(uint256 _amount, bool _isSell) private returns (uint256) {
        uint256 totalFees = _isSell ? SELL_TAX_RATE : BUY_TAX_RATE;
        uint256 feesAmount = _amount.mul(totalFees).div(10**3);
        if(feesAmount == 0) {
            return _amount;
        }
        uint256 buyBackAndBurnFees = _isSell ? feesAmount.mul(SELL_BUY_BACK_BURN_TAX_RATE).div(totalFees) : feesAmount.mul(BUY_BACK_BURN_TAX_RATE).div(totalFees);
        uint256 marketingFees = _isSell ? feesAmount.mul(SELL_MARKETING_DEV_TAX_RATE).div(totalFees) : feesAmount.mul(BUY_MARKETING_DEV_TAX_RATE).div(totalFees);
        uint256 autoLpFees = feesAmount.sub(buyBackAndBurnFees).sub(marketingFees);

        if(buyBackAndBurnFees > 0) {
            buyBackAndBurnAmount += buyBackAndBurnFees;
        }
        if(marketingFees > 0) {
            marketingAmount += marketingFees;
        }
        if(autoLpFees > 0) {
            autoLpAmount += autoLpFees;
        }

        _balances[address(this)] += feesAmount;
        emit Transfer(msg.sender, address(this), feesAmount);
        return _amount - feesAmount;
        
    }

    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }
    
    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
        emit WhitelistUpdated(account, true);
    }
    
    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
        emit WhitelistUpdated(account, false);

    }

    function updateBuyFees(uint256 newAutoLpFee, uint256 newMarketingFee, uint256 newBuyBackAndburnFee) external onlyOwner {
        uint256 newTotalFee = newAutoLpFee.add(newMarketingFee).add(newBuyBackAndburnFee);
        require( newTotalFee <= 200, "cant set fees to more than 20%");

        BUY_AUTO_LP_TAX_RATE = newAutoLpFee;
        BUY_MARKETING_DEV_TAX_RATE = newMarketingFee;
        BUY_BACK_BURN_TAX_RATE = newBuyBackAndburnFee;

        BUY_TAX_RATE = newTotalFee;

        emit BuyFeesUpdated(newAutoLpFee, newMarketingFee, newBuyBackAndburnFee);
    }

    function updateSellFees(uint256 newAutoLpFee, uint256 newMarketingFee, uint256 newBuyBackAndburnFee) external onlyOwner {
        uint256 newTotalFee = newAutoLpFee.add(newMarketingFee).add(newBuyBackAndburnFee);
        require( newTotalFee <= 200, "cant set fees to more than 20%");

        SELL_AUTO_LP_TAX_RATE = newAutoLpFee;
        SELL_MARKETING_DEV_TAX_RATE = newMarketingFee;
        SELL_BUY_BACK_BURN_TAX_RATE = newBuyBackAndburnFee;

        SELL_TAX_RATE = newTotalFee;

        emit SellFeesUpdated(newAutoLpFee, newMarketingFee, newBuyBackAndburnFee);
    }
    
    
    function setMaxTxAmount(uint256 maxTxAmount) external onlyOwner() {
        emit MaxTxAmountUpdated(MAX_TX_AMOUNT, maxTxAmount);
        MAX_TX_AMOUNT = maxTxAmount;

    }
    
    function setMaxWalletLimit(uint256 maxWalletLimit) external onlyOwner() {
        emit MaxWalletLimitUpdated(MAX_WALLET_AMOUNT, maxWalletLimit);
        MAX_WALLET_AMOUNT = maxWalletLimit;
    }

    function setNumTokensSellToAddToLiquidity(uint256 _minimumTokensBeforeSwap) external onlyOwner() {
        emit NumTokensSellToAddToLiquidityUpdated(minimumTokensBeforeSwap, _minimumTokensBeforeSwap);
        minimumTokensBeforeSwap = _minimumTokensBeforeSwap;
    }
    
    function setMarketingAddress(address _MARKETING_ADDRESS) external onlyOwner() {
        emit MarketingAddressUpdated(MARKETING_ADDRESS, _MARKETING_ADDRESS);
        MARKETING_ADDRESS = payable(_MARKETING_ADDRESS);
    }

    function setBuyBackAndBurnAddress(address _BUY_BACK_AND_BURN_ADDRESS) external onlyOwner() {
        emit BuyBackAndBurnAddressUpdated(BUY_BACK_AND_BURN_ADDRESS, _BUY_BACK_AND_BURN_ADDRESS);
        BUY_BACK_AND_BURN_ADDRESS = payable(_BUY_BACK_AND_BURN_ADDRESS);
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    function withdrawUnsupportedTokens(address token, address recipient) external onlyOwner {
        require(token != address(this), "Can not withdraw this token");
        uint256 contractBalance = IERC20(token).balanceOf(address(this));
        IERC20(token).safeTransfer(recipient, contractBalance);

        emit UnsupportedTokensWithdrawn(token, recipient, contractBalance);
    }

    function transferToAddressETH(address payable recipient, uint256 amount) private {
        if(amount == 0) return;
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Unable to send ETH");
    }

    function withdrawETH(address recipient) external onlyOwner {
        (bool success, ) = recipient.call{ value: address(this).balance }("");
        require(success, "unable to send value, recipient may have reverted");
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}


    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
    
     //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}
}