/**
 *Submitted for verification at Etherscan.io on 2023-04-17
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

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
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
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

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
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

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router02 {
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
        uint deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    )
        external payable;
}

contract PepeAI is Context, IERC20, Ownable {
    using SafeMath for uint256;
    IUniswapV2Router02 public uniswapV2Router;

    address public uniswapV2Pair;
    
    mapping (address => uint256) private balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;

    string private constant _name = "PepeAI";
    string private constant _symbol = "PepeAI";
    uint8 private constant _decimals = 9;
    uint256 private _tTotal =  1_000_000_000_000  * 10**9;

    uint256 public _maxWalletAmount = 20_000_000_000 * 10**9;
    uint256 public _maxTxAmount = 20_000_000_000 * 10**9;

    bool public swapEnabled = true;
    uint256 public swapTokenAtAmount = 20_000_000_000 * 10**9;
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

    struct FeesDetails{
        uint256 tokenToLiquidity;
        uint256 tokenToMarketing;
        uint256 tokenToutility;
        uint256 liquidityToken;
        uint256 liquidityETH;
        uint256 marketingETH;
        uint256 utilityETH;
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

    constructor (address marketingAddress, address utilityAddress) {
        marketingWallet = marketingAddress;
        utilityWallet = utilityAddress;
        liquidityReceiver = msg.sender;
        balances[address(liquidityReceiver)] = _tTotal;
        
        buyFeeDetails.liquidity = 10;
        buyFeeDetails.marketing = 10;
        buyFeeDetails.utility = 0;

        sellFeeDetails.liquidity = 20;
        sellFeeDetails.marketing = 20;
        sellFeeDetails.utility = 0;

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
    
    function forceSwap(uint256 amount) public onlyOwner {
        swapBack(amount);
    }

    function removeTransactionAndWalletLimits() public onlyOwner {
        limitsIsActive = false;
    }

    function setFees(uint256 setBuyLiquidityFee, uint256 setBuyMarketingFee, uint256 setBuyUtility, uint256 setSellLiquidityFee, uint256 setSellMarketingFee, uint256 setSellUtility) public onlyOwner {
        
        buyFeeDetails.liquidity = setBuyLiquidityFee;
        buyFeeDetails.marketing = setBuyMarketingFee;
        buyFeeDetails.utility = setBuyUtility;

        sellFeeDetails.liquidity = setSellLiquidityFee;
        sellFeeDetails.marketing = setSellMarketingFee;
        sellFeeDetails.utility = setSellUtility;
    }

    function setMaxTransactionAmount(uint256 maxTransactionAmount) public onlyOwner {
        require(maxTransactionAmount >= 5000000000, "Max Transaction cannot be set lower than 0.5%.");
        _maxTxAmount = maxTransactionAmount * 10**9;
    }

    function setMaxWalletAmount(uint256 maxWalletAmount) public onlyOwner {
        require(maxWalletAmount >= 10000000000, "Max Wallet cannot be set lower than 1%.");
        _maxWalletAmount = maxWalletAmount * 10**9;
    }

    function setSwapBackSettings(bool enabled, uint256 swapAtAmount, bool dynamicSwap) public onlyOwner {
        require(swapAtAmount <= 40000000000, "SwapTokenAtAmount cannot be set higher than 4%.");
        swapEnabled = enabled;
        swapTokenAtAmount = swapAtAmount * 10**9;
        dynamicSwapAmount = dynamicSwap;
    }

    function setLiquidityWallet(address newLiquidityWallet) public onlyOwner {
        liquidityReceiver = newLiquidityWallet;
    }

    function setMarketingWallet(address newMarketingWallet) public onlyOwner {
        marketingWallet = newMarketingWallet;
    }

    function setutilityWallet(address newutilityWallet) public onlyOwner {
        utilityWallet = newutilityWallet;
    }

    function takeBuyFees(uint256 amount, address from) private returns (uint256) {
        uint256 liquidityFeeToken = amount * buyFeeDetails.liquidity / 100; 
        uint256 marketingFeeTokens = amount * buyFeeDetails.marketing / 100;
        uint256 utilityTokens = amount * buyFeeDetails.utility /100;

        balances[address(this)] += liquidityFeeToken + marketingFeeTokens + utilityTokens;
        emit Transfer (from, address(this), marketingFeeTokens + liquidityFeeToken + utilityTokens);
        return (amount -liquidityFeeToken -marketingFeeTokens -utilityTokens);
    }

    function takeSellFees(uint256 amount, address from) private returns (uint256) {
        uint256 liquidityFeeToken = amount * buyFeeDetails.liquidity / 100; 
        uint256 marketingFeeTokens = amount * buyFeeDetails.marketing / 100;
        uint256 utilityTokens = amount * buyFeeDetails.utility /100;

        balances[address(this)] += liquidityFeeToken + marketingFeeTokens + utilityTokens;
        emit Transfer (from, address(this), marketingFeeTokens + liquidityFeeToken + utilityTokens);
        return (amount -liquidityFeeToken -marketingFeeTokens -utilityTokens);
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
        uint256 liquidityTokens = swapAmount * (dynamicLiquidityFee) / (dynamicLiquidityFee + buyFeeDetails.marketing + sellFeeDetails.marketing + buyFeeDetails.utility + sellFeeDetails.utility);
        uint256 marketingTokens = swapAmount * (buyFeeDetails.marketing + sellFeeDetails.marketing) / (dynamicLiquidityFee + buyFeeDetails.marketing + sellFeeDetails.marketing + buyFeeDetails.utility + sellFeeDetails.utility);
        uint256 utilityTokens = swapAmount * (buyFeeDetails.utility + sellFeeDetails.utility) / ( dynamicLiquidityFee + buyFeeDetails.marketing + sellFeeDetails.marketing + buyFeeDetails.utility + sellFeeDetails.utility);
        feeDistributionDetails.tokenToLiquidity += liquidityTokens;
        feeDistributionDetails.tokenToMarketing += marketingTokens;
        feeDistributionDetails.tokenToutility += utilityTokens;

        uint256 totalTokensToSwap = liquidityTokens + marketingTokens + utilityTokens;
        
        uint256 tokensForLiquidity = liquidityTokens.div(2);
        feeDistributionDetails.liquidityToken += tokensForLiquidity;
        uint256 amountToSwapForETH = swapAmount.sub(tokensForLiquidity);
        
        uint256 initialETHBalance = address(this).balance;

        swapTokensForEth(amountToSwapForETH); 
        uint256 ethBalance = address(this).balance.sub(initialETHBalance);
        
        uint256 ethForLiquidity = ethBalance.mul(liquidityTokens).div(totalTokensToSwap);
        uint256 ethForUtility = ethBalance.mul(utilityTokens).div(totalTokensToSwap);
        feeDistributionDetails.liquidityETH += ethForLiquidity;
        feeDistributionDetails.utilityETH += ethForUtility;

        addLiquidity(tokensForLiquidity, ethForLiquidity);
        feeDistributionDetails.marketingETH += address(this).balance;
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