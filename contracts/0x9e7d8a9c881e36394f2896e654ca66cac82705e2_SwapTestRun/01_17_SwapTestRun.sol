// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./SwapGovernance.sol";
import "./SwapStructs.sol";

/**
 * @title KeyPairSwap
 * @dev contract to call 1inch router to swap assets
 * successful.
 */
contract SwapTestRun is SwapGovernance {
    using SafeERC20 for IERC20;

    using SafeMath for uint256;

    event Swapped(
        address sender,
        IERC20 srcToken,
        IERC20 dstToken,
        uint256 spentAmount,
        uint256 returnAmount
    );

    /**
     * Contract initialization.
     */
    constructor(
        address _feeCollector,
        address _1inchRouter,
        address _0xRouter
    ) {
        setFeeCollector(_feeCollector);
        set1InchRouter(_1inchRouter);
        set0xRouter(_0xRouter);
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /**
     * @dev SwapTestRun Tokens on 0x.
     * @param _0xData a 0x data to call aggregate router to swap assets.
     */
    function _swapToken0x(
        bytes calldata _0xData,
        uint256 amount,
        address srcAddr,
        address dstAddr
    ) internal returns (uint256) {
        SwapStructs._0xSwapDescription memory swapDescriptionObj = abi.decode(
            _0xData[4 :],
            (SwapStructs._0xSwapDescription)
        );
        if (swapDescriptionObj.inputToken == 0x0000000000000000000000000000000000000080) {
            // this is because as sometime 0x send data like sellToPancakeSwap or sellToUniswapSwap
            (address[] memory tokens, uint256 sellAmount, ,) = abi.decode(
                _0xData[4 :],
                (address[], uint256, uint256, uint8)
            );
            swapDescriptionObj.inputToken = tokens[0];
            swapDescriptionObj.outputToken = tokens[tokens.length - 1];
            swapDescriptionObj.inputTokenAmount = sellAmount;
        }

        uint256 outputCurrencyBalanceBeforeSwap = 0;

        address inputToken = swapDescriptionObj.inputToken;
        if (srcAddr != address(0)) {
            inputToken = srcAddr;
        }

        address outputToken = swapDescriptionObj.outputToken;
        if (dstAddr != address(0)) {
            outputToken = dstAddr;
        }

        // this if else is to save output token balance
        if (address(outputToken) == NATIVE_ADDRESS) {
            outputCurrencyBalanceBeforeSwap = address(this).balance;
        } else {
            IERC20 swapOutputToken = IERC20(outputToken);
            outputCurrencyBalanceBeforeSwap = swapOutputToken.balanceOf(address(this));
        }
        // end of else

        uint256 amountForNative = 0;
        if (address(inputToken) == NATIVE_ADDRESS || inputToken == address(0)) {
            // It means we are trying to transfer with Native amount
            uint256 feeAmount = (msg.value).mul(FEE_PERCENT).div(FEE_PERCENT_DENOMINATOR);
            amountForNative = (msg.value).sub(feeAmount);
            require(amountForNative >= swapDescriptionObj.inputTokenAmount, "Key Pair: NATIVE_ADDRESS Amount Not match with Swap Amount.");
            if (feeAmount > 0) {
                payable(FEE_COLLECTOR).transfer(feeAmount);
            }
        } else {
            uint256 feeAmount = (amount).mul(FEE_PERCENT).div(FEE_PERCENT_DENOMINATOR);
            IERC20 swapSrcToken = IERC20(inputToken);
            require((amount).sub(feeAmount) >= swapDescriptionObj.inputTokenAmount, "Key Pair: Amount Not match with Swap Amount.");
            if (swapSrcToken.allowance(address(this), OxAggregatorRouter) < amount) {
                swapSrcToken.safeApprove(OxAggregatorRouter, MAX_INT);
            }
            require(
                swapSrcToken.balanceOf(msg.sender) >= amount,
                "Key Pair: You have insufficient balance to swap"
            );
            swapSrcToken.safeTransferFrom(msg.sender, address(this), amount);
            if (feeAmount > 0) {
                swapSrcToken.transfer(FEE_COLLECTOR, feeAmount);
            }
        }

        (bool success,) = address(OxAggregatorRouter).call{value : amountForNative}(_0xData);
        require(success, "Key Pair: Swap Return Failed");
        uint256 outputCurrencyBalanceAfterSwap = 0;
        // Again this check is to maintain for sending receiver balance to msg.sender
        if (address(outputToken) == NATIVE_ADDRESS || outputToken == address(0)) {
            outputCurrencyBalanceAfterSwap = address(this).balance;
            outputCurrencyBalanceAfterSwap = outputCurrencyBalanceAfterSwap - outputCurrencyBalanceBeforeSwap;
            require(outputCurrencyBalanceAfterSwap > 0, "Key Pair: NATIVE_ADDRESS Transfer output amount should be greater than 0.");
            payable(msg.sender).transfer(outputCurrencyBalanceAfterSwap);
        } else {
            IERC20 swapOutputToken = IERC20(outputToken);
            outputCurrencyBalanceAfterSwap = swapOutputToken.balanceOf(address(this));
            outputCurrencyBalanceAfterSwap = outputCurrencyBalanceAfterSwap - outputCurrencyBalanceBeforeSwap;
            require(outputCurrencyBalanceAfterSwap > 0, "Key Pair: Transfer output amount should be greater than 0.");
            swapOutputToken.safeTransfer(msg.sender, outputCurrencyBalanceAfterSwap);
        }

        emit Swapped(
            msg.sender,
            IERC20(swapDescriptionObj.inputToken),
            IERC20(swapDescriptionObj.outputToken),
            amount,
            outputCurrencyBalanceAfterSwap
        );
        // end of else
        // Now need to transfer fund to destination address.
        return outputCurrencyBalanceAfterSwap;
    } // end of swap function

    /**
     * @dev SwapTestRun Tokens on 1inch.
     * @param _1inchData a 1inch data to call aggregate router to swap assets.
     */
    function _swapToken1Inch(
        bytes calldata _1inchData,
        uint256 amountArg,
        uint256 functionCode,
        address inputToken,
        address outputToken,
        address srcAddr
    ) internal returns (uint256) {
        IERC20 srcTokenFinal;
        uint256 amountFinal = 0;
        if (functionCode == 1) {
            (, SwapStructs._1inchSwapDescription memory swapDescriptionObj, ,) = abi.decode(
                _1inchData[4 :],
                (address, SwapStructs._1inchSwapDescription, bytes, bytes)
            );
            srcTokenFinal = swapDescriptionObj.srcToken;
            amountFinal = swapDescriptionObj.amount;
        } else if (functionCode == 2) {
            (, IERC20 srcToken, uint256 amount,,) = abi.decode(_1inchData[4 :], (address, IERC20, uint256, uint256, uint256[]));
            srcTokenFinal = srcToken;
            amountFinal = amount;
        } else if (functionCode == 3) {
            (, uint256 amount,,) = abi.decode(_1inchData[4 :], (address, uint256, uint256, uint256[]));
            srcTokenFinal = IERC20(inputToken);
            amountFinal = amount;
        } else {
            revert("Key Pair: Invalid function code");
        }

        uint256 amountForNative = 0;
        if (address(srcTokenFinal) == NATIVE_ADDRESS || srcTokenFinal == IERC20(address(0))) {
            uint256 feeAmount = (msg.value).mul(FEE_PERCENT).div(FEE_PERCENT_DENOMINATOR);
            require(
                (msg.value).sub(feeAmount) >= amountFinal,
                "Key Pair: Amount Not match with Swap Amount."
            );
            amountForNative = amountFinal;

            if (feeAmount > 0) {
                payable(FEE_COLLECTOR).transfer(feeAmount);
            }
        } else {
            uint256 feeAmount = (amountArg).mul(FEE_PERCENT).div(FEE_PERCENT_DENOMINATOR);
            require(
                (amountArg).sub(feeAmount) >= amountFinal,
                "Key Pair: Amount Not match with Swap Amount."
            );
            IERC20 swapSrcToken = IERC20(srcTokenFinal);
            if (srcAddr != address(0)) {
                swapSrcToken = IERC20(srcAddr);
            }
            if (swapSrcToken.allowance(address(this), oneInchAggregatorRouter) < amountFinal) {
                swapSrcToken.safeApprove(oneInchAggregatorRouter, MAX_INT);
            }
            // when calling from unlock by payload, need to use smart contract fund.
            require(swapSrcToken.balanceOf(msg.sender) >= amountArg, "Key Pair: You have insufficient balance to swap");
            swapSrcToken.safeTransferFrom(msg.sender, address(this), amountArg);
            if (feeAmount > 0) {
                swapSrcToken.transfer(FEE_COLLECTOR, feeAmount);
            }
        }

        // end of else
        (bool success, bytes memory _returnData) = address(oneInchAggregatorRouter).call{value : amountForNative}(
            _1inchData
        );
        require(success, "Key Pair: Swap Return Failed");

        uint256 returnAmount = 0;
        if (functionCode == 1) {
            (returnAmount,) = abi.decode(_returnData, (uint256, uint256));
        } else if (functionCode == 2 || functionCode == 3) {
            (returnAmount) = abi.decode(_returnData, (uint256));
        }

        emit Swapped(
            msg.sender,
            IERC20(inputToken),
            IERC20(outputToken),
            amountArg,
            returnAmount
        );

        return returnAmount;
    } // end of swap function

    /**
     * @dev SwapTestRun Tokens on Chain.
     * @param _1inchData a 1inch data to call aggregate router to swap assets.
     */
    function swapTokens(
        bytes calldata _1inchData,
        bytes calldata _0xData,
        uint256 amount,
        uint256 functionCode,
        address inputToken,
        address outputToken
    ) external payable virtual returns (uint256) {
        if (_1inchData.length > 1) {
            return _swapToken1Inch(_1inchData, amount, functionCode, inputToken, outputToken, address(0));
        } else if (_0xData.length > 1) {
            return _swapToken0x(_0xData, amount, address(0), address(0));
        }
        return 0;
    }

    receive() external payable {}
} // end of class