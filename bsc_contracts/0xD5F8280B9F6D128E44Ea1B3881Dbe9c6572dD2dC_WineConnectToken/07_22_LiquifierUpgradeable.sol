// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

import "./OwnableUpgradeable.sol";

abstract contract LiquifierUpgradeable is Initializable, OwnableUpgradeable { 

    using SafeMathUpgradeable for uint256;

    uint256 private _withdrawableBalance;

    IUniswapV2Router02 internal _router;
    address internal _pair;
    
    bool private inSwapAndLiquify;
    bool private swapAndLiquifyEnabled;

    uint256 private maxTransactionAmount;
    uint256 private numberOfTokensToSwapToLiquidity;

    uint256 internal marketingTokens;
    uint256 internal eventTokens;
    uint256 internal liquidityTokens;

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    event RouterSet(address indexed router);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiquidity);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event LiquidityAdded(uint256 tokenAmountSent, uint256 ethAmountSent, uint256 liquidity);

    receive() external payable {}

    function __Liquifier_init(uint256 maxTx_, uint256 liquifyAmount_) internal onlyInitializing {
        __Liquifier_init_unchained(maxTx_, liquifyAmount_);
    }

    function __Liquifier_init_unchained(uint256 maxTx_, uint256 liquifyAmount_) internal onlyInitializing {
        _setRouterAddress(0x10ED43C718714eb63d5aA57B78B54704E256024E);

        // testnet: 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3
        // mainnet: 0x10ED43C718714eb63d5aA57B78B54704E256024E

        maxTransactionAmount = maxTx_;
        numberOfTokensToSwapToLiquidity = liquifyAmount_;

        swapAndLiquifyEnabled = true;
    }

    function _setRouterAddress(address router) private {
        IUniswapV2Router02 _newPancakeRouter = IUniswapV2Router02(router);

        _pair = IUniswapV2Factory(_newPancakeRouter.factory()).createPair(address(this), _newPancakeRouter.WETH());
        _router = _newPancakeRouter;

        emit RouterSet(router);
    }

    function liquify(address sender) internal {
        uint256 contractTokenBalance = marketingTokens + eventTokens + liquidityTokens;
        if (contractTokenBalance >= maxTransactionAmount) 
            contractTokenBalance = maxTransactionAmount;
        
        bool isOverRequiredTokenBalance = ( contractTokenBalance >= numberOfTokensToSwapToLiquidity );
        if ( isOverRequiredTokenBalance && swapAndLiquifyEnabled && !inSwapAndLiquify && (sender != _pair) )
            _swapAndLiquify(contractTokenBalance);
    }

    function _swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _router.WETH();

        uint256 ethValue = _router.getAmountsOut(contractTokenBalance, path)[1];

        if (ethValue > 0) {
            uint256 initialBalance = address(this).balance;

            uint256 liquidityHalf = liquidityTokens.div(2);
            uint256 liquidityToken = liquidityTokens.sub(liquidityHalf);
            uint256 toSell = marketingTokens + eventTokens + liquidityHalf;
            
            _swapTokensForEth(toSell, path);
            
            uint256 ethGained = address(this).balance - initialBalance;

            uint256 liquidityETH = (ethGained * ((liquidityHalf * 10**18) / contractTokenBalance)) / 10**18;
            uint256 marketingETH = (ethGained * ((marketingTokens * 10**18) / contractTokenBalance)) / 10**18;
            uint256 eventETH = (ethGained * ((eventTokens * 10**18) / contractTokenBalance)) / 10**18;

            if (ethGained - (marketingETH + eventETH + liquidityETH) > 0)
                marketingETH += ethGained - (marketingETH + eventETH + liquidityETH);

            uint256 amountLiqToken = _addLiquidity(liquidityToken, liquidityETH);
            uint256 remainingTokens = contractTokenBalance - (toSell + amountLiqToken); 

            if (remainingTokens > 0)
                _transferRemainingLiquifiedTokens(remainingTokens);

            _transferLiquifiedEventETH(eventETH);
            _transferLiquifiedMarketingETH(marketingETH);

            marketingTokens = 0;
            eventTokens = 0;
            liquidityTokens = 0;

            _withdrawableBalance = address(this).balance;
        }
    }

    function _swapTokensForEth(uint256 tokenAmount, address[] memory path) private {
        _approveDelegate(address(this), address(_router), tokenAmount);

        _router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function _addLiquidity(uint256 tokenAmount, uint256 ethAmount) private returns(uint256) {
        _approveDelegate(address(this), address(_router), tokenAmount);

        (uint256 tokenAmountSent, uint256 ethAmountSent, uint256 liquidity) = _router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            owner(),
            block.timestamp
        );

        emit LiquidityAdded(tokenAmountSent, ethAmountSent, liquidity);

        return tokenAmountSent;
    }

    function setRouterAddress(address router) external onlyOwner {
        _setRouterAddress(router);
    }

    function setSwapAndLiquifyEnabled(bool enabled) external onlyOwner {
        swapAndLiquifyEnabled = enabled;
        emit SwapAndLiquifyEnabledUpdated(swapAndLiquifyEnabled);
    }

    function withdrawLockedEth(address payable recipient) external onlyOwner {
        require(recipient != address(0), "Cannot withdraw the ETH balance to the zero address");
        require(_withdrawableBalance > 0, "The ETH balance must be greater than 0");

        uint256 amount = _withdrawableBalance;
        _withdrawableBalance = 0;
        recipient.transfer(amount);
    }

    function triggerLiquify() public onlyOwner {
        liquify(address(0));
    }

    function _approveDelegate(address owner, address spender, uint256 amount) internal virtual;

    function _transferLiquifiedEventETH(uint256 amount) internal virtual;

    function _transferLiquifiedMarketingETH(uint256 amount) internal virtual;

    function _transferRemainingLiquifiedTokens(uint256 tAmount) internal virtual;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}