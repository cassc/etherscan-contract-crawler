// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Storage.sol";
import "./interfaces/IWETH.sol";

contract ParalaxExchange is Storage, ReentrancyGuard {
    using SafeERC20 for IERC20;

    event LimitOrderDEX(
        bytes sign,
        address account,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] path
    );
    event LimitOrderP2P(
        bytes sign1,
        bytes sign2,
        address addrOne,
        address addrTwo,
        uint256 amountInOne,
        uint256 amountInTwo
    );
    event SwapDex(
        address account,
        uint256 amountIn,
        uint256 amountOut,
        address[] path
    );

    event TimeMultiplierDCA(
        bytes sign,
        TimeMultiplier tm,
        uint256 amountIn,
        address account
    );

    event LevelOrderDCA(bytes sign, OrderDCA order, uint256 amountIn);

    receive() external payable {}

    /**
     * @notice Swaps an exact amount of input tokens for as many output tokens as possible,
     * along the route determined by the path. The first element of path is the input token,
     * the last is the output token, and any intermediate elements represent intermediate pairs to trade through
     * (if, for example, a direct pair does not exist).
     */

    function swapDex(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path
    ) external {
        (uint256 newAmountIn, uint256 tax) = subtractPercentage(
            amountIn,
            feeDEX
        );

        _transferTax(path[0], msg.sender, tax);
        IERC20(path[0]).safeTransferFrom(
            msg.sender,
            address(this),
            newAmountIn
        );

        uint256[] memory amounts = _swapDex(
            newAmountIn,
            amountOutMin,
            path,
            msg.sender
        );

        emit SwapDex(
            msg.sender,
            newAmountIn,
            amounts[amounts.length - 1],
            path
        );
    }

    /**
     * @notice Swaps an exact amount of ETH for as many output tokens as possible,
     * along the route determined by the path.
     * The first element of path must be WETH, the last is the output token,
     * and any intermediate elements represent intermediate pairs to trade through
     * (if, for example, a direct pair does not exist).
     */
    function swapDexETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path
    ) external payable {
        address wETH = IUniswapV2Router02(_adapter).WETH();
        require(path[0] == wETH || path[path.length - 1] == wETH, "Bad path");
        uint256 newAmountIn;
        uint256 tax;
        uint256[] memory amounts;
        if (path[0] == wETH) {
            require(msg.value == amountIn, "ETH amount error");
            (newAmountIn, tax) = subtractPercentage(msg.value, feeDEX);

            amounts = IUniswapV2Router02(_adapter).swapExactETHForTokens{
                value: newAmountIn
            }(amountOutMin, path, msg.sender, block.timestamp);
            _transferTaxETH(tax);
        } else {
            (newAmountIn, tax) = subtractPercentage(amountIn, feeDEX);
            IERC20(path[0]).safeTransferFrom(
                msg.sender,
                address(this),
                newAmountIn
            );
            _approve(path[0]);

            _transferTax(path[0], msg.sender, tax);

            amounts = IUniswapV2Router02(_adapter).swapExactTokensForETH(
                newAmountIn,
                amountOutMin,
                path,
                msg.sender,
                block.timestamp
            );
        }

        emit SwapDex(
            msg.sender,
            newAmountIn,
            amounts[amounts.length - 1],
            path
        );
    }

    /**

    * @notice p2p trading. Exchanges tokens between two users.
    * Users sign "SignerData", then these data are compared with each other.
    * Opposite orders exchange tokens.
    */
    function limitOrderP2P(
        bytes calldata sign1,
        bytes calldata sign2,
        SignerData memory signerData1,
        SignerData memory signerData2
    ) external nonReentrant {
        _validateData(sign1, sign2, signerData1, signerData2);

        //if the first call of this order
        if (_signerDatas[sign1].account != address(0))
            signerData1 = _signerDatas[sign1];

        // if the first call of this order
        if (_signerDatas[sign2].account != address(0))
            signerData2 = _signerDatas[sign2];

        //we get the amount to transfer
        (
            uint256 amountTransferFromSignerOne,
            uint256 amountTransferFromSignerTwo
        ) = _swapLimitOrderP2P(signerData1, signerData2);

        // update data
        _signerDatas[sign1] = signerData1;
        _signerDatas[sign2] = signerData2;

        // subtract fee
        (
            uint256 newAmountFromSignerOne,
            uint256 taxFromSignerOne
        ) = subtractPercentage(amountTransferFromSignerOne, feeLMP2P);
        (
            uint256 newAmountFromSignerTwo,
            uint256 taxFromSignerTwo
        ) = subtractPercentage(amountTransferFromSignerTwo, feeLMP2P);

        // transfering taxes to the treasure
        _transferTax(
            signerData1.baseCurrency,
            signerData1.account,
            taxFromSignerOne
        );
        _transferTax(
            signerData2.baseCurrency,
            signerData2.account,
            taxFromSignerTwo
        );
        //transferring funds from user 1 to user 2
        if (signerData1.baseCurrency != _wETH) {
            IERC20(signerData1.baseCurrency).safeTransferFrom(
                signerData1.account,
                signerData2.account,
                newAmountFromSignerOne
            );
        } else {
            // we debit WETH from the user and convert them into ETH
            // and we send them to the user
            IERC20(signerData1.baseCurrency).safeTransferFrom(
                signerData1.account,
                address(this),
                newAmountFromSignerOne
            );

            _transferETH(newAmountFromSignerOne, signerData2.account);
        }
        // transferring funds from user 2 to user 1
        if (signerData2.baseCurrency != _wETH) {
            IERC20(signerData2.baseCurrency).safeTransferFrom(
                signerData2.account,
                signerData1.account,
                newAmountFromSignerTwo
            );
        } else {
            // we debit WETH from the user and convert them into ETH
            // and we send them to the user
            IERC20(signerData2.baseCurrency).safeTransferFrom(
                signerData2.account,
                address(this),
                newAmountFromSignerTwo
            );

            _transferETH(newAmountFromSignerTwo, signerData1.account);
        }

        emit LimitOrderP2P(
            sign1,
            sign2,
            signerData1.account,
            signerData2.account,
            newAmountFromSignerOne,
            newAmountFromSignerTwo
        );
    }

    /**
     * @notice Сalling a pre-signed order to exchange for DEX.
     * @param sign signature generated by "signerData"
     * @param signerData order data
     * @param path the path to exchange to uniswap V2
     */
    function limitOrderDEX(
        bytes calldata sign,
        SignerData memory signerData,
        address[] calldata path
    ) external {
        require(_verifySignerData(sign, signerData), "Sign Error");

        if (_signerDatas[sign].account != address(0)) {
            signerData = _signerDatas[sign];
        }

        require(
            signerData.deadline >= block.timestamp || signerData.deadline == 0,
            "Deadline expired"
        );
        require(signerData.amount != 0, "Already executed");

        uint256 amountIn = signerData.amount;

        // subtract fee
        (uint256 newAmountIn, uint256 tax) = subtractPercentage(
            amountIn,
            feeLMDEX
        );

        // transfering taxes to the treasure
        _transferTax(path[0], signerData.account, tax);
        IERC20(path[0]).safeTransferFrom(
            signerData.account,
            address(this),
            newAmountIn
        );

        //we get the minimum amount that the user should receive according to the signed data
        uint8 decimalsQuote = IERC20Metadata(signerData.quoteCurrency)
            .decimals();
        uint256 amountOutMin = _calcQuoteAmount(
            newAmountIn,
            decimalsQuote,
            signerData.price
        );
        // exchange for DEX
        uint256[] memory amounts;
        if (signerData.quoteCurrency != _wETH) {
            // exchange ERC20
            amounts = _swapDex(
                newAmountIn,
                amountOutMin,
                path,
                signerData.account
            );
        } else {
            // exchange ETH
            amounts = _swapDex(newAmountIn, amountOutMin, path, address(this));
            uint transferAmount = amounts[amounts.length - 1];

            _transferETH(transferAmount, signerData.account);
        }

        signerData.amount = 0;
        // update signerData
        _signerDatas[sign] = signerData;

        emit LimitOrderDEX(
            sign,
            signerData.account,
            newAmountIn,
            amounts[amounts.length - 1],
            path
        );
    }

    function orderDCATM(
        bytes calldata sign,
        Order memory order,
        address[] calldata path
    ) public {
        require(_verifyOrder(order, sign), "Sign Error");
        OrderDCA memory orderDca = _ordersDCA[sign];
        // checking for the first entry
        if (_isEmptyDCA(orderDca)) {
            // first entry
            require(_verificationDCA(order.dca), "Verification DCA");
            if (_emptyTM(order.tm)) {
                // first entry without TM
                _levelDCA(sign, order.dca, path);
            } else {
                //first entry with TM

                uint8 decimalsBase = IERC20Metadata(order.dca.baseCurrency)
                    .decimals();
                uint8 decimalsQuote = IERC20Metadata(order.dca.quoteCurrency)
                    .decimals();

                uint256 convertedPrice = _convertPrice(
                    decimalsBase,
                    decimalsQuote,
                    order.dca.price
                );

                order.tm.amount =
                    (order.tm.amount * (10 ** decimalsBase)) /
                    convertedPrice;
                _levelTM(sign, order.dca, order.tm, path);
            }
            _ordersDCA[sign] = order.dca;
            _timeMultipliers[sign] = order.tm;
        } else {
            // subsequent entry
            if (_emptyTM(order.tm)) {
                // entry without TM
                _levelDCA(sign, order.dca, path);
            } else {
                // entry with TM
                _dcaTM(sign, path);
            }
        }
    }

    function _verificationDCA(
        OrderDCA memory orderDca
    ) internal pure returns (bool) {
        return (orderDca.volume != 0 &&
            orderDca.baseCurrency != address(0) &&
            orderDca.quoteCurrency != address(0) &&
            orderDca.account != address(0));
    }

    function _isEmptyDCA(
        OrderDCA memory orderDca
    ) internal pure returns (bool) {
        return (orderDca.volume == 0 ||
            orderDca.baseCurrency == address(0) ||
            orderDca.quoteCurrency == address(0) ||
            orderDca.account == address(0));
    }

    /**
     * @notice execution of a DCA order with TimeMultiplier
     * @param sign signature generated by "Order"
     * @param path the path to exchange to uniswap V2
     */
    function _dcaTM(bytes calldata sign, address[] calldata path) internal {
        TimeMultiplier memory tm = _timeMultipliers[sign];
        ProcessingDCA memory procDCA = _processingDCA[sign];
        OrderDCA memory order = _ordersDCA[sign];

        if (procDCA.doneTM == tm.amount && tm.amount != 0) {
            // completing levels in DCA after completing "Time multiplier"
            require(order.volume != 0, "Init Error");

            require(_validatePriceDCA(order, path), "Price Error");

            _levelDCA(sign, order, path);
        } else {
            // completing levels in "Time multiplier"
            require(order.volume != 0, "Init Error");

            require(procDCA.done < order.volume, "Order Error");

            require(procDCA.doneTM < tm.amount, "TM: Order Error");

            require(_validatePriceDCA(order, path), "Price Error");

            require(tm.amount != 0, "TM: Init Error");

            _levelTM(sign, order, tm, path);
        }
        require(
            procDCA.done + procDCA.doneTM <= order.volume,
            "The order has already been made"
        );
    }

    /**
     * @notice exchange of tokens for "uniswap"
     */
    function _swapDex(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] memory path,
        address account
    ) internal returns (uint256[] memory amounts) {
        _approve(path[0]);

        amounts = _exchangeDex(amountIn, amountOutMin, path, account);
    }

    /**
     * @notice comparison of two prices. The difference should not exceed a delta
     */
    function _validateDelta(
        uint256 price,
        uint256 convertedPrice
    ) internal view {
        int256 signedDelta = int256(100 * PRECISION) -
            int256((price * 100 * PRECISION) / convertedPrice);

        uint256 actualDelta = (signedDelta < 0)
            ? uint256(signedDelta * -1)
            : uint256(signedDelta);

        require(actualDelta <= _delta, "Prices Error");
    }

    /**
     * @dev Validate main properties of the DCA order
     */
    function _validateOrderDCA(
        OrderDCA memory order
    ) internal pure returns (bool) {
        return
            order.volume != 0 &&
            // order.price != 0 &&
            order.levels != 0 &&
            order.period != 0;
    }

    /**
     * @dev Validate trigger price for the DCA order
     */
    function _validatePriceDCA(
        OrderDCA memory order,
        address[] calldata path
    ) internal view returns (bool) {
        if (order.price == 0) return true;

        (uint256 amountOutMin, uint256 actualAmountOut) = _getQuotePrice(
            order,
            0,
            path
        );

        return actualAmountOut >= amountOutMin;
    }

    /**
     * @dev Validate state of the DCA order
     */
    function _validateInitDCA(bytes memory sign) internal view returns (bool) {
        return
            _ordersDCA[sign].volume == 0 && _timeMultipliers[sign].amount == 0;
    }

    /**
     * @dev Validate time multiplier struct
     */
    function _validateTMDCA(Order memory order) internal pure returns (bool) {
        return
            order.tm.amount != 0 &&
            order.tm.interval != 0 &&
            order.tm.amount <= order.dca.volume;
    }

    /**
     * @dev Validate TM struct, should be empty.
     */
    function _emptyTM(TimeMultiplier memory tm) internal pure returns (bool) {
        return tm.amount == 0 && tm.interval == 0;
    }

    /**
     * @dev Get a quote asset price for the DCA order
     */
    function _getQuotePrice(
        OrderDCA memory order,
        uint256 amountIn,
        address[] calldata path
    ) internal view returns (uint256, uint256) {
        require(
            path[0] == order.baseCurrency &&
                path[path.length - 1] == order.quoteCurrency,
            "BAD PATH"
        );
        if (order.price == 0) return (0, 0);
        if (amountIn == 0) {
            amountIn = order.volume / order.levels;
        }

        (uint256 newAmountIn, ) = subtractPercentage(amountIn, feeDCA);

        uint8 decimalsBase = IERC20Metadata(order.baseCurrency).decimals();
        uint8 decimalsQuote = IERC20Metadata(order.quoteCurrency).decimals();

        (uint256 slippedPrice, ) = addPercentage(order.price, order.slippage);

        uint256 convertedPrice = _convertPrice(
            decimalsBase,
            decimalsQuote,
            slippedPrice
        );

        uint256 amountOutMin = (newAmountIn * convertedPrice) /
            10 ** decimalsBase;

        uint256[] memory amounts = _getAmountsOut(path, newAmountIn);

        return (amountOutMin, amounts[amounts.length - 1]);
    }

    /**
     * @notice execution of DCA level logic
     */
    function _levelDCA(
        bytes memory sign,
        OrderDCA memory order,
        address[] calldata path
    ) internal {
        ProcessingDCA memory procDCA = _processingDCA[sign];
        require(
            block.timestamp >= procDCA.lastLevel + order.period,
            "Period Error"
        );
        uint256 scaleAmount = _getScaleAmount(order, procDCA);

        procDCA.scaleAmount = scaleAmount;
        procDCA.lastLevel = block.timestamp;
        procDCA.done += scaleAmount;
        _processingDCA[sign] = procDCA;

        _proceedLevel(order, scaleAmount, path);

        emit LevelOrderDCA(sign, order, scaleAmount);
    }

    /**
     * @notice Getting the amount to exchange at the current level
     */
    function _getScaleAmount(
        OrderDCA memory order,
        ProcessingDCA memory procDCA
    ) internal pure returns (uint256 scaleAmount) {
        if (procDCA.done == 0 || (procDCA.done != 0 && order.scale == 0)) {
            scaleAmount = (order.volume - procDCA.doneTM) / order.levels;
        } else {
            uint256 scalingValue = procDCA.scaleAmount;
            (scaleAmount, ) = addPercentage(scalingValue, order.scale);
        }
        uint256 totalDone = procDCA.done + procDCA.doneTM;
        scaleAmount = (order.volume - totalDone < scaleAmount)
            ? order.volume - totalDone
            : scaleAmount;
    }

    function _levelTM(
        bytes memory sign,
        OrderDCA memory order,
        TimeMultiplier memory tm,
        address[] calldata path
    ) internal returns (uint256 amountIn) {
        ProcessingDCA memory procDCA = _processingDCA[sign];
        require(
            block.timestamp >= procDCA.lastLevel + tm.interval,
            "Interval Error"
        );

        uint256 scaleAmount;
        if (procDCA.doneTM == 0 || (procDCA.doneTM != 0 && order.scale == 0)) {
            scaleAmount = tm.amount / order.levels;
        } else {
            (scaleAmount, ) = addPercentage(procDCA.scaleAmount, order.scale);
        }

        if (tm.amount - procDCA.doneTM <= scaleAmount) {
            amountIn = tm.amount - procDCA.doneTM;

            procDCA.scaleAmount = 0;
            // procDCA.lastLevel = 0;
        } else {
            amountIn = scaleAmount;

            procDCA.scaleAmount = amountIn;
            procDCA.lastLevel = block.timestamp;
        }
        procDCA.doneTM += amountIn;
        _processingDCA[sign] = procDCA;

        _proceedLevel(order, amountIn, path);

        emit TimeMultiplierDCA(sign, tm, amountIn, order.account);
    }

    function _proceedLevel(
        OrderDCA memory order,
        uint256 amountIn,
        address[] calldata path
    ) internal {
        (uint256 newAmountIn, uint256 tax) = subtractPercentage(
            amountIn,
            feeDCA
        );

        _transferTax(order.baseCurrency, order.account, tax);
        IERC20(order.baseCurrency).safeTransferFrom(
            order.account,
            address(this),
            newAmountIn
        );

        (uint256 amountOutMin, ) = _getQuotePrice(order, amountIn, path);
        if (order.quoteCurrency != _wETH) {
            _swapDex(newAmountIn, amountOutMin, path, order.account);
        } else {
            uint256[] memory amounts = _swapDex(
                newAmountIn,
                amountOutMin,
                path,
                address(this)
            );

            _transferETH(amounts[amounts.length - 1], order.account);
        }
    }

    /**
     * @notice Checking the data of two orders
     */
    function _validateData(
        bytes calldata sign1,
        bytes calldata sign2,
        SignerData memory signerData1,
        SignerData memory signerData2
    ) internal view {
        require(_verifySignerData(sign1, signerData1), "Sign1 Error");
        require(_verifySignerData(sign2, signerData2), "Sign2 Error");
        require(
            signerData1.baseCurrency == signerData2.quoteCurrency &&
                signerData1.quoteCurrency == signerData2.baseCurrency,
            "SignData error"
        );
        require(
            (signerData1.deadline >= block.timestamp) ||
                (signerData1.deadline == 0),
            "Deadline expired signer1"
        );
        require(
            (signerData2.deadline >= block.timestamp) ||
                (signerData1.deadline == 0),
            "Deadline expired signer2"
        );
    }

    /**
     * @notice calculation of the amount to be exchanged between orders
     * @return signerOneQuoteAmount - the amount of toxins that must be written off
     *  from the second user and transferred to the first
     * @return signerTwoQuoteAmount - the amount of toxins that must be written off
     *  from the second user and transferred to the first
     */
    function _calcCostQuote(
        SignerData memory signerData1,
        SignerData memory signerData2
    )
        internal
        view
        returns (uint256 signerOneQuoteAmount, uint256 signerTwoQuoteAmount)
    {
        uint8 decimalsBase = IERC20Metadata(signerData1.baseCurrency)
            .decimals();
        uint8 decimalsQuote = IERC20Metadata(signerData1.quoteCurrency)
            .decimals();

        uint256 convertedPrice = _convertPrice(
            decimalsBase,
            decimalsQuote,
            signerData1.price
        );

        _validateDelta(signerData2.price, convertedPrice);

        signerOneQuoteAmount = _calcQuoteAmount(
            signerData1.amount,
            decimalsQuote,
            signerData1.price
        );

        signerTwoQuoteAmount = _calcQuoteAmount(
            signerData2.amount,
            decimalsBase,
            signerData2.price
        );
    }

    /**
     * @notice price conversion from base currency to quote
     */
    function _convertPrice(
        uint256 decimalsBase,
        uint256 decimalsQuote,
        uint256 price
    ) internal pure returns (uint256 convertedPrice) {
        convertedPrice = (10 ** decimalsBase * 10 ** decimalsQuote) / price;
    }

    /**
     * @notice calculation of the amount in the quote currency
     */
    function _calcQuoteAmount(
        uint256 amount,
        uint256 decimals,
        uint256 price
    ) internal pure returns (uint256 quoteAmount) {
        quoteAmount = (amount * 10 ** decimals) / price;
    }

    /**
     * @notice calculation of the amount to be exchanged between two orders
     * @param signerData1 order for comparison
     * @param signerData2 order for comparison
     * @return amountTransferFromSignerOne - the amount of toxins that must be written off
     *  from the first user and transferred to the second
     * @return amountTransferFromSignerTwo - the amount of toxins that must be written off
     *  from the second user and transferred to the first
     */
    function _swapLimitOrderP2P(
        SignerData memory signerData1,
        SignerData memory signerData2
    )
        internal
        view
        returns (
            uint256 amountTransferFromSignerOne,
            uint256 amountTransferFromSignerTwo
        )
    {
        (
            uint256 signerOneQuoteAmount,
            uint256 signerTwoQuoteAmount
        ) = _calcCostQuote(signerData1, signerData2);

        if (signerData1.amount >= signerTwoQuoteAmount) {
            amountTransferFromSignerOne = signerTwoQuoteAmount;
            amountTransferFromSignerTwo = signerData2.amount;

            signerData1.amount -= signerTwoQuoteAmount;
            signerData2.amount = 0;
        } else {
            amountTransferFromSignerOne = signerData1.amount;
            amountTransferFromSignerTwo = signerOneQuoteAmount;
            signerData1.amount = 0;
            signerData2.amount -= signerOneQuoteAmount;
        }
    }

    /**
     * @notice calls the "approve" function to the router address
     */
    function _approve(address token) internal {
        if (IERC20(token).allowance(address(this), _adapter) == 0) {
            IERC20(token).approve(_adapter, type(uint256).max);
        }
    }

    function _exchangeDex(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] memory path,
        address account
    ) internal returns (uint256[] memory amounts) {
        uint256 deadline = block.timestamp + 2 minutes;
        amounts = IUniswapV2Router02(_adapter).swapExactTokensForTokens(
            amountIn,
            amountOutMin,
            path,
            account,
            deadline
        );
    }

    /**
     * @dev Transfer tax to the treasure
     */
    function _transferTaxETH(uint256 tax) internal {
        (bool success, ) = payable(_treasure).call{value: tax}("");
        require(success, "ETH transfer error");
    }

    /**
     * @dev Transfer tax to the treasure
     */
    function _transferTax(
        address asset,
        address from,
        uint256 amount
    ) internal {
        IERC20(asset).safeTransferFrom(from, _treasure, amount);
    }

    /**
     * @notice exchanges WETH for ETH. Sends them to the address
     */
    function _transferETH(uint amount, address account) internal {
        IWETH(_wETH).withdraw(amount);
        (bool success, ) = account.call{value: amount}("");
        require(success, "ETH transfer error");
    }

    /**
     * @notice checks the address that signed the hashed message (`hash`) with  `signature`.
     * @param signature signature received from the user
     * @param  signerData the "SignerData" data structure is required for signature verification
     */
    function _verifySignerData(
        bytes calldata signature,
        SignerData memory signerData
    ) private view returns (bool status) {
        bytes32 hashStruct = _hashStructSignerData(signerData);
        status = EIP712._verify(signerData.account, signature, hashStruct);
    }

    /**
     * @notice checks the address that signed the hashed message (`hash`) with  `signature`.
     * @param signature signature received from the user
     * @param order the "Order" data structure is required for signature verification
     */
    function _verifyOrder(
        Order memory order,
        bytes calldata signature
    ) private view returns (bool status) {
        bytes32 hashOrder = _hashOrderDCA(order);
        status = EIP712._verify(order.dca.account, signature, hashOrder);
    }

    /**
     * @notice hashing struct "signerData"
     */
    function _hashStructSignerData(
        SignerData memory signerData
    ) private pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    SIGNER_DATA,
                    signerData.account,
                    signerData.baseCurrency,
                    signerData.deadline,
                    signerData.quoteCurrency,
                    signerData.price,
                    signerData.amount,
                    signerData.nonce
                )
            );
    }

    /**
     * @notice hashing struct "OrderDCA"
     */
    function _hashStructOrderDCA(
        OrderDCA memory orderDCA
    ) private pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    ORDER_DCA,
                    orderDCA.price,
                    orderDCA.volume,
                    orderDCA.levels,
                    orderDCA.period,
                    orderDCA.slippage,
                    orderDCA.baseCurrency,
                    orderDCA.scale,
                    orderDCA.quoteCurrency,
                    orderDCA.account,
                    orderDCA.nonce
                )
            );
    }

    /**
     * @notice hashing struct "TimeMultiplier"
     */
    function _hashStructTM(
        TimeMultiplier memory tm
    ) private pure returns (bytes32) {
        return keccak256(abi.encode(TIME_MULTIPLIER, tm.amount, tm.interval));
    }

    /**
     * @notice hashing struct "Order"
     */
    function _hashOrderDCA(Order memory order) private pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    ORDER,
                    _hashStructOrderDCA(order.dca),
                    _hashStructTM(order.tm)
                )
            );
    }

    /**
     * @dev UniswapV2Router02 getAmountsOut function
     */
    function _getAmountsOut(
        address[] memory path,
        uint256 amount
    ) internal view returns (uint256[] memory amountsOut) {
        amountsOut = IUniswapV2Router02(_adapter).getAmountsOut(amount, path);
    }
}