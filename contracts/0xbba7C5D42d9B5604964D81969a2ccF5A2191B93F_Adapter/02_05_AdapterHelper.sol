// SPDX-License-Identifier: --DAO--

/**
 * @author René Hochmuth
 * @author Vitally Marinchenko
 */

pragma solidity =0.8.19;

import "./AdapterDeclarations.sol";

error SlippageTooBig();
error ChainLinkOffline();

abstract contract AdapterHelper is AdapterDeclarations {

    /**
    * @dev Tells TokenProfit contract to perform a swap through UniswapV2 starting with ETH
    */
    function _executeSwapWithValue(
        address[] memory _path,
        uint256 _amount,
        uint256 _minAmountOut
    )
        internal
        returns (uint256[] memory)
    {
        if (_minAmountOut == 0) {
            revert SlippageTooBig();
        }

        bytes memory callbackData = tokenProfit.executeAdapterRequestWithValue(
            UNIV2_ROUTER_ADDRESS,
            abi.encodeWithSelector(
                IUniswapV2.swapExactETHForTokens.selector,
                _minAmountOut,
                _path,
                TOKEN_PROFIT_ADDRESS,
                block.timestamp
            ),
            _amount
        );

        return abi.decode(
            callbackData,
            (
                uint256[]
            )
        );
    }

    /**
    * @dev checks if chainLink price feeds are still operating
    */
    function isChainlinkOffline()
        public
        view
        returns (bool)
    {
        for (uint256 i = 0; i < TOKENS; i++) {

            IChainLink feed = tokens[i].feedLink;

            (   ,
                ,
                ,
                uint256 upd
                ,
            ) = feed.latestRoundData();

            upd = block.timestamp > upd
                ? block.timestamp - upd
                : block.timestamp;

            if (upd > chainLinkHeartBeat[address(feed)]) return true;
        }

        return false;
    }

    /**
    * @dev Calculates ETH and token balances available for services
    * --------------------------------
    * availableEther is ETH balance of the TokenProfit contract
    * availableTokens is balances of all tokens in TokenProfit contract
    * etherAmount is availableEther + ETH deposited in other services
    * tokenAmounts is availableTokens + tokens deposited in other services
    */
    function getTokenAmounts()
        public
        view
        returns (
            uint256 etherAmount,
            uint256[] memory tokensAmounts,
            uint256 availableEther,
            uint256[] memory availableAmounts
        )
    {
        uint256[] memory tokenAmounts = new uint256[](TOKENS);
        uint256[] memory availableTokens = new uint256[](TOKENS);

        (
            availableEther,
            availableTokens
        ) = _getAvailableFunds();

        for (uint256 i = 0; i < TOKENS; i++) {
            tokenAmounts[i] = _getReservesByToken(
                tokens[i].tokenERC20
            ) + availableTokens[i];
        }

        etherAmount = _calculateAmountFromShares(
            liquidNFTsWETHPool,
            TOKEN_PROFIT_ADDRESS
        ) + availableEther;

        return (
            etherAmount,
            tokenAmounts,
            availableEther,
            availableTokens
        );
    }

    function _calculateTotalEthValue(
        uint256 _msgValue
    )
        internal
        view
        returns (uint256)
    {
        if (isChainlinkOffline() == true) {
            revert ChainLinkOffline();
        }

        (
            uint256 etherAmount,
            uint256[] memory tokensAmounts,
            ,
        ) = getTokenAmounts();

        for (uint256 i = 0; i < TOKENS; i++) {

            TokenData memory token = tokens[i];
            IChainLink feed = token.feedLink;

            uint256 latestAnswer = feed.latestAnswer();

            require(
                latestAnswer > 0,
                "AdapterHelper: CHAINLINK_OFFLINE"
            );

            etherAmount += feed.latestAnswer()
                * PRECISION_FACTOR
                * tokensAmounts[i]
                / (10 ** token.tokenDecimals)
                / (10 ** token.feedDecimals);
        }

        return etherAmount
            - _msgValue;
    }

    /**
    * @dev Tells TokenProfit contract to perform
    * a swap through UniswapV2 starting with Tokens
    */
    function _executeSwap(
        address[] memory _path,
        uint256 _amount,
        uint256 _minAmountOut
    )
        internal
        returns (uint256[] memory)
    {
        if (_minAmountOut == 0) {
            revert SlippageTooBig();
        }

        bytes memory callbackData = tokenProfit.executeAdapterRequest(
            UNIV2_ROUTER_ADDRESS,
            abi.encodeWithSelector(
                IUniswapV2.swapExactTokensForETH.selector,
                _amount,
                _minAmountOut,
                _path,
                TOKEN_PROFIT_ADDRESS,
                block.timestamp
            )
        );

        return abi.decode(
            callbackData,
            (
                uint256[]
            )
        );
    }

    /**
    * @dev Tells TokenProfit contract to convert WETH to ETH
    */
    function _unwrapETH(
        uint256 _amount
    )
        internal
    {
        tokenProfit.executeAdapterRequest(
            WETH_ADDRESS,
            abi.encodeWithSelector(
                IWETH.withdraw.selector,
                _amount
            )
        );
    }

    /**
    * @dev Tells TokenProfit contract to convert ETH to WETH
    */
    function _wrapETH(
        uint256 _amount
    )
        internal
    {
        tokenProfit.executeAdapterRequestWithValue(
            WETH_ADDRESS,
            abi.encodeWithSelector(
                IWETH.deposit.selector
            ),
            _amount
        );
    }

    /**
    * @dev Tells TokenProfit contract to deposit funds into LiquidNFTs pool
    */
    function _depositLiquidNFTsWrapper(
        ILiquidNFTsPool _pool,
        uint256 _amount
    )
        internal
    {
        tokenProfit.executeAdapterRequest(
            LIQUID_NFT_ROUTER_ADDRESS,
            abi.encodeWithSelector(
                ILiquidNFTsRouter.depositFunds.selector,
                _amount,
                _pool
            )
        );
    }

    /**
    * @dev Tells TokenProfit contract to withdraw funds from LiquidNFTs pool
    */
    function _withdrawLiquidNFTsWrapper(
        ILiquidNFTsPool _pool,
        uint256 _amount
    )
        internal
    {
        tokenProfit.executeAdapterRequest(
            LIQUID_NFT_ROUTER_ADDRESS,
            abi.encodeWithSelector(
                ILiquidNFTsRouter.withdrawFunds.selector,
                _calculateSharesFromAmount(
                    _pool,
                    _amount
                ),
                _pool
            )
        );
    }

    /**
    * @dev Routine used to deal with all services withdrawing USDC
    */
    function _USDCRoutine(
        uint256 _amount
    )
        internal
        returns (uint256)
    {
        uint256 balanceBefore = USDC.balanceOf(
            TOKEN_PROFIT_ADDRESS
        );

        _withdrawLiquidNFTsWrapper(
            liquidNFTsUSDCPool,
            _amount
        );

        uint256 balanceAfter = USDC.balanceOf(
            TOKEN_PROFIT_ADDRESS
        );

        return balanceAfter - balanceBefore;
    }

    /**
    * @dev Routine used to deal with all services withdrawing ETH
    */
    function _WETHRoutine(
        uint256 _amount
    )
        internal
        returns (uint256)
    {
        _withdrawLiquidNFTsWrapper(
            liquidNFTsWETHPool,
            _amount
        );

        uint256 balance = WETH.balanceOf(
            TOKEN_PROFIT_ADDRESS
        );

        _unwrapETH(
            balance
        );

        return balance;
    }

    /**
    * @dev Returns balances of TokenProfit contract - tokens and ETH
    */
    function _getAvailableFunds()
        internal
        view
        returns (
            uint256,
            uint256[] memory
        )
    {
        uint256[] memory availableTokens = new uint256[](TOKENS);

        for (uint256 i = 0; i < TOKENS; i++) {
            IERC20 token = tokens[i].tokenERC20;
            availableTokens[i] = token.balanceOf(
                TOKEN_PROFIT_ADDRESS
            );
        }

        uint256 availableEther = TOKEN_PROFIT_ADDRESS.balance;

        return (
            availableEther,
            availableTokens
        );
    }

    /**
    * @dev Returns balances locked in servcies based on token
    */
    function _getReservesByToken(
        IERC20 _token
    )
        internal
        view
        returns (uint256)
    {
        if (_token == USDC) {
            return _calculateAmountFromShares(
                liquidNFTsUSDCPool,
                TOKEN_PROFIT_ADDRESS
            );
        }

        return 0;
    }

    /**
    * @dev Helper function to calculate shares from amount for LiquidNFTs pool
    */
    function _calculateSharesFromAmount(
        ILiquidNFTsPool _pool,
        uint256 _amount
    )
        internal
        view
        returns (uint256)
    {
        return _amountSharesCalculationWrapper(
            _pool.totalInternalShares(),
            _pool.pseudoTotalTokensHeld(),
            _amount
        );
    }

    /**
    * @dev Helper function to calculate amount from shares for LiquidNFTs pool
    */
    function _calculateAmountFromShares(
        ILiquidNFTsPool _pool,
        address _sharesHolder
    )
        internal
        view
        returns (uint256)
    {
        return _amountSharesCalculationWrapper(
            _pool.pseudoTotalTokensHeld(),
            _pool.totalInternalShares(),
            _pool.internalShares(
                _sharesHolder
            )
        );
    }

    /**
    * @dev Calculates ratios based on shares and amount
    */
    function _amountSharesCalculationWrapper(
        uint256 _totalValue,
        uint256 _correspondingTotalValue,
        uint256 _amountValue
    )
        internal
        pure
        returns (uint256)
    {
        return _totalValue
            * _amountValue
            / _correspondingTotalValue;
    }
}