// SPDX-License-Identifier: MIT

/*
Telegram: https://t.me/vibrantblock
Website: https://vibrantblock.io
**/

import './IERC20.sol';
import './SafeMath.sol';
import './Ownable.sol';
import './IUniswapV2Factory.sol';
import './IUniswapV2Router02.sol';

pragma solidity ^0.8.19;

contract VibrantBlock is Context, IERC20, Ownable {
    using SafeMath for uint256;
    IUniswapV2Router02 public uniswapV2Router;

    address public uniswapV2Pair;
    
    mapping (address => uint256) private balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;

    string private constant _name = "Vibrant Block";
    string private constant _symbol = "VIBRANT";
    uint8 private constant _decimals = 18;
    uint256 private _tTotal =  100000000000000  * 10**18;

    uint256 public _maxWalletAmount = 2000000000000 * 10**18;
    uint256 public _maxTxAmount = 2000000000000 * 10**18;

    bool public swapEnabled = true;
    uint256 public swapTokenAtAmount = 1000000000000 * 10**18;
    bool public dynamicSwapAmount = true;
    
    uint256 targetLiquidity = 200;
    uint256 targetLiquidityDenominator = 100;

    address public liquidityReceiver;
    address public rndWallet;

    bool public limitsIsActive = true;

    struct BuyFees{
        uint256 liquidity;
        uint256 rnd;
    }

    struct SellFees{
        uint256 liquidity;
        uint256 rnd;
    }

    struct FeesDetails{
        uint256 tokenToLiquidity;
        uint256 tokenToRnd;
        uint256 tokenToutility;
        uint256 liquidityToken;
        uint256 liquidityETH;
        uint256 rndETH;
    }

    struct LiquidityDetails{
        uint256 targetLiquidity;
        uint256 currentLiquidity;
    }

    BuyFees public buyFeeDetails;
    SellFees public sellFeeDetails;
    FeesDetails public feeDistributionDetails;
    LiquidityDetails public liquidityDetails;

    bool private swapping;
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiquidity);

    constructor (address rndAddress) {
        rndWallet = rndAddress;
        liquidityReceiver = msg.sender;
        balances[address(liquidityReceiver)] = _tTotal;
        
        buyFeeDetails.liquidity = 5;
        buyFeeDetails.rnd = 15;

        sellFeeDetails.liquidity = 10;
        sellFeeDetails.rnd = 30;

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;
        
        _isExcludedFromFee[msg.sender] = true;
        _isExcludedFromFee[rndWallet] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[address(0x00)] = true;
        _isExcludedFromFee[address(0xdead)] = true;

        
        emit Transfer(address(0), address(msg.sender), _tTotal);
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

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return balances[account];
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()] - amount);
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
    
    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFee[address(account)] = excluded;
    }

    function getCirculatingSupply() public view returns (uint256) {
        return _tTotal.sub(balanceOf(address(0x00000))).sub(balanceOf(address(0x0dead)));
    }

    function getLiquidityBacking(uint256 accuracy) public view returns (uint256) {
        return accuracy.mul(balanceOf(address(uniswapV2Pair)).mul(2)).div(getCirculatingSupply());
    }

    function isOverLiquified(uint256 target, uint256 accuracy) public view returns (bool) {
        return getLiquidityBacking(accuracy) > target;
    }

    receive() external payable {}
    
    function forceSwap(uint256 amount) public onlyOwner {
        swapBack(amount);
    }

    function removeTransactionAndWalletLimits() public onlyOwner {
        limitsIsActive = false;
    }

    function setFees(uint256 setBuyLiquidityFee, uint256 setBuyRndFee, uint256 setSellLiquidityFee, uint256 setSellRndFee) public onlyOwner {
        require(setBuyLiquidityFee + setBuyRndFee <= 25, "Total buy fee cannot be set higher than 25%.");
        require(setSellLiquidityFee + setSellRndFee <= 25, "Total sell fee cannot be set higher than 25%.");

        buyFeeDetails.liquidity = setBuyLiquidityFee;
        buyFeeDetails.rnd = setBuyRndFee;

        sellFeeDetails.liquidity = setSellLiquidityFee;
        sellFeeDetails.rnd = setSellRndFee;
    }

    function setMaxTransactionAmount(uint256 maxTransactionAmount) public onlyOwner {
        require(maxTransactionAmount >= 5000000000, "Max Transaction cannot be set lower than 0.5%.");
        _maxTxAmount = maxTransactionAmount * 10**18;
    }

    function setMaxWalletAmount(uint256 maxWalletAmount) public onlyOwner {
        require(maxWalletAmount >= 10000000000, "Max Wallet cannot be set lower than 1%.");
        _maxWalletAmount = maxWalletAmount * 10**18;
    }

    function setSwapBackSettings(bool enabled, uint256 swapAtAmount, bool dynamicSwap) public onlyOwner {
        require(swapAtAmount <= 20000000000, "SwapTokenAtAmount cannot be set higher than 2%.");
        swapEnabled = enabled;
        swapTokenAtAmount = swapAtAmount * 10**18;
        dynamicSwapAmount = dynamicSwap;
    }

    function setLiquidityWallet(address newLiquidityWallet) public onlyOwner {
        liquidityReceiver = newLiquidityWallet;
    }

    function setRndWallet(address newRndWallet) public onlyOwner {
        rndWallet = newRndWallet;
    }

    function setTargetliquidity(uint256 newTargetLiquidity, uint256 newTargetLiquidityDenominator) public onlyOwner {
        targetLiquidity = newTargetLiquidity;
        targetLiquidityDenominator = newTargetLiquidityDenominator;
    }

    function takeBuyFees(uint256 amount, address from) private returns (uint256) {
        uint256 liquidityFeeToken = amount * buyFeeDetails.liquidity / 100; 
        uint256 rndFeeTokens = amount * buyFeeDetails.rnd / 100;

        balances[address(this)] += liquidityFeeToken + rndFeeTokens;
        emit Transfer (from, address(this), rndFeeTokens + liquidityFeeToken);
        return (amount -liquidityFeeToken -rndFeeTokens);
    }

    function takeSellFees(uint256 amount, address from) private returns (uint256) {
        uint256 liquidityFeeToken = amount * buyFeeDetails.liquidity / 100; 
        uint256 rndFeeTokens = amount * buyFeeDetails.rnd / 100;

        balances[address(this)] += liquidityFeeToken + rndFeeTokens;
        emit Transfer (from, address(this), rndFeeTokens + liquidityFeeToken);
        return (amount -liquidityFeeToken -rndFeeTokens);
    }

    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        
        balances[from] -= amount;
        uint256 transferAmount = amount;
        
        bool takeFee;

        if(!_isExcludedFromFee[from] && !_isExcludedFromFee[to]){
            takeFee = true;
        }

        if(takeFee){
            if(to != uniswapV2Pair && from == uniswapV2Pair){
                if(limitsIsActive) {
                    require(amount <= _maxTxAmount, "Transfer Amount exceeds the maxTxnsAmount");
                    require(balanceOf(to) + amount <= _maxWalletAmount, "Transfer amount exceeds the maxWalletAmount.");
                }
                transferAmount = takeBuyFees(amount, to);
            }

            if(from != uniswapV2Pair && to == uniswapV2Pair){
                if(limitsIsActive) {
                    require(amount <= _maxTxAmount, "Transfer Amount exceeds the maxTxnsAmount");
                }
                transferAmount = takeSellFees(amount, from);

               if (swapEnabled && balanceOf(address(this)) >= swapTokenAtAmount && !swapping) {
                    swapping = true;
                    if(!dynamicSwapAmount || transferAmount >= swapTokenAtAmount) {
                        swapBack(swapTokenAtAmount);
                    } else {
                        swapBack(transferAmount);
                    }
                    swapping = false;
              }
            }

            if(to != uniswapV2Pair && from != uniswapV2Pair){
                if(limitsIsActive) {
                    require(amount <= _maxTxAmount, "Transfer Amount exceeds the maxTxnsAmount");
                    require(balanceOf(to) + amount <= _maxWalletAmount, "Transfer amount exceeds the maxWalletAmount.");
                }
            }
        }
        
        balances[to] += transferAmount;
        emit Transfer(from, to, transferAmount);
    }
   
    function swapBack(uint256 amount) private {
        uint256 swapAmount = amount;
        uint256 dynamicLiquidityFee = isOverLiquified(targetLiquidity, targetLiquidityDenominator) ? 0 : (buyFeeDetails.liquidity + sellFeeDetails.liquidity);
        uint256 liquidityTokens = swapAmount * (dynamicLiquidityFee) / (dynamicLiquidityFee + buyFeeDetails.rnd + sellFeeDetails.rnd);
        uint256 rndTokens = swapAmount * (buyFeeDetails.rnd + sellFeeDetails.rnd) / (dynamicLiquidityFee + buyFeeDetails.rnd + sellFeeDetails.rnd);
        feeDistributionDetails.tokenToLiquidity += liquidityTokens;
        feeDistributionDetails.tokenToRnd += rndTokens;

        uint256 totalTokensToSwap = liquidityTokens + rndTokens;
        
        uint256 tokensForLiquidity = liquidityTokens.div(2);
        feeDistributionDetails.liquidityToken += tokensForLiquidity;
        uint256 amountToSwapForETH = swapAmount.sub(tokensForLiquidity);
        
        uint256 initialETHBalance = address(this).balance;

        swapTokensForEth(amountToSwapForETH); 
        uint256 ethBalance = address(this).balance.sub(initialETHBalance);
        
        uint256 ethForLiquidity = ethBalance.mul(liquidityTokens).div(totalTokensToSwap);
        feeDistributionDetails.liquidityETH += ethForLiquidity;

        addLiquidity(tokensForLiquidity, ethForLiquidity);
        feeDistributionDetails.rndETH += address(this).balance;
        payable(rndWallet).transfer(address(this).balance);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
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

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.addLiquidityETH {value: ethAmount} (
            address(this),
            tokenAmount,
            0,
            0,
            liquidityReceiver,
            block.timestamp
        );
    }

    function withdrawForeignToken(address tokenContract) public onlyOwner {
        IERC20(tokenContract).transfer(address(msg.sender), IERC20(tokenContract).balanceOf(address(this)));
    }
}