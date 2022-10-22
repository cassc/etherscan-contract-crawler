// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

/**
There are far too many uses for the LP swapping pool.
Rather than rewrite them, this contract performs them for us and uses both generic and specific calls.
-The Dev
*/
import '@pancakeswap/pancake-swap-lib/contracts/token/BEP20/IBEP20.sol';
import '@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

abstract contract LPSwapSupportUpgradeable is OwnableUpgradeable {
    using SafeMathUpgradeable for uint256;

    event UpdateRouter(address indexed newAddress, address indexed oldAddress);
    event UpdatePair(address indexed newAddress, address indexed oldAddress);
    event UpdateLPReceiver(address indexed newAddress, address indexed oldAddress);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event BuybackAndLiquifyEnabledUpdated(bool enabled);

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 currencyReceived,
        uint256 tokensIntoLiquidty
    );

    event BuybackAndLiquify(
        uint256 tokensBought,
        uint256 currencyIntoLiquidty
    );

    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    bool internal inSwap;
    bool public swapsEnabled;
    bool public buybackAndLiquifyEnabled;

    uint256 public minSpendAmount;
    uint256 public maxSpendAmount;

    uint256 public minTokenSpendAmount;
    uint256 public maxTokenSpendAmount;

    IUniswapV2Router02 public pancakeRouter;
    address public pancakePair;
    address public liquidityReceiver;
    address public deadAddress;

    // Workaround for buyback liquify transaction failures when using proxies.
    // Requires an address that is effectively dead to use as a custodian.
    // Should not be modifiable or an account owned by any user.
    address public buybackEscrowAddress;

    mapping(address => bool) public isLPPoolAddress;

    function __LPSwapSupport_init(address lpReceiver) internal onlyInitializing {
        __Ownable_init();
        __LPSwapSupport_init_unchained(lpReceiver);
    }

    function __LPSwapSupport_init_unchained(address lpReceiver) internal onlyInitializing {
        deadAddress = address(0x000000000000000000000000000000000000dEaD);
        buybackEscrowAddress = address(0x000000000000000000000000000000000000bEEF);

        liquidityReceiver = lpReceiver;
        buybackAndLiquifyEnabled = true;
        minSpendAmount = 2 ether;
        maxSpendAmount = 100 ether;
    }

    function _approve(address holder, address spender, uint256 tokenAmount) internal virtual;
    function _balanceOf(address holder) internal view virtual returns(uint256);

    function updateRouter(address newAddress) public onlyOwner {
        require(newAddress != address(pancakeRouter), "The router is already set to this address");
        emit UpdateRouter(newAddress, address(pancakeRouter));
        pancakeRouter = IUniswapV2Router02(newAddress);
    }

    function updateLiquidityReceiver(address receiverAddress) external onlyOwner {
        require(receiverAddress != liquidityReceiver, "LP is already sent to that address");
        emit UpdateLPReceiver(receiverAddress, liquidityReceiver);
        liquidityReceiver = receiverAddress;
    }

    function updateRouterAndPair(address newAddress) public virtual onlyOwner {
        if(newAddress != address(pancakeRouter)){
            updateRouter(newAddress);
        }
        address _pancakeswapV2Pair = IUniswapV2Factory(pancakeRouter.factory()).createPair(address(this), pancakeRouter.WETH());
        if(_pancakeswapV2Pair != pancakePair){
            updateLPPair(_pancakeswapV2Pair);
        }
    }

    function updateLPPair(address newAddress) public virtual onlyOwner {
        require(newAddress != pancakePair, "The LP Pair is already set to this address");
        emit UpdatePair(newAddress, pancakePair);
        updateLPPoolList(newAddress, true);
        pancakePair = newAddress;
    }

    function updateLPPoolList(address newAddress, bool _isPoolAddress) public virtual onlyOwner {
        isLPPoolAddress[newAddress] = _isPoolAddress;
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapsEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    function setBuybackAndLiquifyEnabled(bool _enabled) public onlyOwner {
        buybackAndLiquifyEnabled = _enabled;
        emit BuybackAndLiquifyEnabledUpdated(_enabled);
    }

    function swapAndLiquify(uint256 tokens) internal {
        // split the contract balance into halves
        uint256 half = tokens.div(2);
        uint256 otherHalf = tokens.sub(half);

        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // swap tokens for
        swapTokensForCurrencyUnchecked(half);

        // how much did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);

        // add liquidity to uniswap
        addLiquidity(otherHalf, newBalance);

        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function swapTokensForCurrency(uint256 tokenAmount) internal returns(uint256){
        return swapTokensForCurrencyAdv(address(this), tokenAmount, address(this));
    }

    function swapTokensForCurrencyUnchecked(uint256 tokenAmount) private returns(uint256){
        return _swapTokensForCurrencyAdv(address(this), tokenAmount, address(this));
    }

    function swapTokensForCurrencyAdv(address tokenAddress, uint256 tokenAmount, address destination) internal returns(uint256){

        if(tokenAmount < minTokenSpendAmount){
            return 0;
        }
        if(maxTokenSpendAmount != 0 && tokenAmount > maxTokenSpendAmount){
            tokenAmount = maxTokenSpendAmount;
        }
        return _swapTokensForCurrencyAdv(tokenAddress, tokenAmount, destination);
    }

    function _swapTokensForCurrencyAdv(address tokenAddress, uint256 tokenAmount, address destination) private returns(uint256){
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = tokenAddress;
        path[1] = pancakeRouter.WETH();
        uint256 tokenCurrentBalance;
        if(tokenAddress != address(this)){
            bool approved = IBEP20(tokenAddress).approve(address(pancakeRouter), tokenAmount);
            if(!approved){
                return 0;
            }
            tokenCurrentBalance = IBEP20(tokenAddress).balanceOf(address(this));
        } else {
            _approve(address(this), address(pancakeRouter), tokenAmount);
            tokenCurrentBalance = _balanceOf(address(this));
        }
        if(tokenCurrentBalance < tokenAmount){
            return 0;
        }

        // make the swap
        pancakeRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            destination,
            block.timestamp
        );

        return tokenAmount;
    }

    function addLiquidity(uint256 tokenAmount, uint256 cAmount) private {

        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(pancakeRouter), tokenAmount);

        // add the liquidity
        pancakeRouter.addLiquidityETH{value: cAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            liquidityReceiver,
            block.timestamp
        );
    }

    function swapCurrencyForTokens(uint256 amount) internal {
        swapCurrencyForTokensAdv(address(this), amount, address(this));
    }

    function swapCurrencyForTokensAdv(address tokenAddress, uint256 amount, address destination) internal {
        if(amount > maxSpendAmount){
            amount = maxSpendAmount;
        }
        if(amount < minSpendAmount) {
            return;
        }

        _swapCurrencyForTokensAdv(tokenAddress, amount, destination);
    }

    function swapCurrencyForTokensUnchecked(address tokenAddress, uint256 amount, address destination) internal {
        _swapCurrencyForTokensAdv(tokenAddress, amount, destination);
    }

    function _swapCurrencyForTokensAdv(address tokenAddress, uint256 amount, address destination) private {
        address[] memory path = new address[](2);
        path[0] = pancakeRouter.WETH();
        path[1] = tokenAddress;
        if(amount > address(this).balance){
            amount = address(this).balance;
        }

        // make the swap
        pancakeRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
            0,
            path,
            destination,
            block.timestamp
        );
    }

    function buybackAndLiquify(uint256 amount) internal returns(uint256 remainder) {
        uint256 half = amount.div(2);
        uint256 initialTokenBalance = _balanceOf(address(this));
        // Buyback tokens
        swapCurrencyForTokensUnchecked(address(this), half, buybackEscrowAddress);

        // Add liquidity to pair
        uint256 _buybackTokensPending = _balanceOf(buybackEscrowAddress);
        _approve(buybackEscrowAddress, address(this), _buybackTokensPending);
        IBEP20(address(this)).transferFrom(buybackEscrowAddress, address(this), _buybackTokensPending);
        addLiquidity(_buybackTokensPending, amount.sub(half));

        emit BuybackAndLiquify(_buybackTokensPending, half);
        uint256 finalTokenBalance = _balanceOf(address(this));

        remainder = finalTokenBalance > initialTokenBalance ? finalTokenBalance.sub(initialTokenBalance) : 0;
    }

    function forceBuybackAndLiquify() external virtual onlyOwner {
        require(address(this).balance > 0, "Contract has no funds to use for buyback");
        buybackAndLiquify(address(this).balance);
    }

    function updateTokenSwapRange(uint256 minAmount, uint256 maxAmount) external onlyOwner {
        require(minAmount < maxAmount || maxAmount == 0, "Minimum must be less than maximum unless max is 0 (Unlimited)");
        require(minAmount != 0, "Minimum cannot be set to 0");
        minTokenSpendAmount = minAmount;
        maxTokenSpendAmount = maxAmount;
    }

    function updateCurrencySwapRange(uint256 minAmount, uint256 maxAmount) external onlyOwner {
        require(minAmount <= maxAmount || maxAmount == 0, "Minimum must be less than maximum unless max is 0 (Unlimited)");
        require(minAmount != 0, "Minimum cannot be set to 0");
        minSpendAmount = minAmount;
        maxSpendAmount = maxAmount;
    }
}