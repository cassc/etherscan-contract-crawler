// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "../../ApeSwapZap.sol";
import "./lib/ICustomBill.sol";

abstract contract ApeSwapZapTBills is ApeSwapZap {
    using SafeERC20 for IERC20;

    event ZapTBill(ICustomBill bill, IERC20 principalToken, uint256 depositAmount, uint256 payoutAmount);

    /// @notice Zap single token to LP
    /// @param inputToken Input token to zap
    /// @param inputAmount Amount of input tokens to zap
    /// @param lpTokens Tokens of LP to zap to
    /// @param path0 Path from input token to LP token0
    /// @param path1 Path from input token to LP token1
    /// @param minAmountsSwap The minimum amount of output tokens that must be received for swap
    /// @param minAmountsLP AmountAMin and amountBMin for adding liquidity
    /// @param deadline Unix timestamp after which the transaction will revert
    /// @param bill Treasury bill address
    /// @param maxPrice Max price of treasury bill
    function zapTBill(
        IERC20 inputToken,
        uint256 inputAmount,
        address[] memory lpTokens, //[tokenA, tokenB]
        address[] calldata path0,
        address[] calldata path1,
        uint256[] memory minAmountsSwap, //[A, B]
        uint256[] memory minAmountsLP, //[amountAMin, amountBMin]
        uint256 deadline,
        ICustomBill bill,
        uint256 maxPrice
    ) external nonReentrant {
        IApePair principalToken = _validateTBillZap(lpTokens, bill);
        inputAmount = _transferIn(inputToken, inputAmount);
        _zap(
            ZapParams({
                inputToken: inputToken,
                inputAmount: inputAmount,
                lpTokens: lpTokens,
                path0: path0,
                path1: path1,
                minAmountsSwap: minAmountsSwap,
                minAmountsLP: minAmountsLP,
                to: address(this),
                deadline: deadline
            }),
            false
        );

        (uint256 depositAmount, uint256 payoutAmount) = _depositTBill(
            bill,
            IERC20(address(principalToken)),
            maxPrice,
            msg.sender
        );
        emit ZapTBill(bill, IERC20(address(principalToken)), depositAmount, payoutAmount);
    }

    /// @notice Zap native token to Treasury Bill
    /// @param lpTokens Tokens of LP to zap to
    /// @param path0 Path from input token to LP token0
    /// @param path1 Path from input token to LP token1
    /// @param minAmountsSwap The minimum amount of output tokens that must be received for swap
    /// @param minAmountsLP AmountAMin and amountBMin for adding liquidity
    /// @param deadline Unix timestamp after which the transaction will revert
    /// @param bill Treasury bill address
    /// @param maxPrice Max price of treasury bill
    function zapTBillNative(
        address[] memory lpTokens, //[tokenA, tokenB]
        address[] calldata path0,
        address[] calldata path1,
        uint256[] memory minAmountsSwap, //[A, B]
        uint256[] memory minAmountsLP, //[amountAMin, amountBMin]
        uint256 deadline,
        ICustomBill bill,
        uint256 maxPrice
    ) external payable nonReentrant {
        IApePair principalToken = _validateTBillZap(lpTokens, bill);
        (IERC20 weth, uint256 inputAmount) = _wrapNative();
        _zap(
            ZapParams({
                inputToken: weth,
                inputAmount: inputAmount,
                lpTokens: lpTokens,
                path0: path0,
                path1: path1,
                minAmountsSwap: minAmountsSwap,
                minAmountsLP: minAmountsLP,
                to: address(this),
                deadline: deadline
            }),
            true
        );

        (uint256 depositAmount, uint256 payoutAmount) = _depositTBill(
            bill,
            IERC20(address(principalToken)),
            maxPrice,
            msg.sender
        );
        emit ZapTBill(bill, IERC20(address(principalToken)), depositAmount, payoutAmount);
    }

    /// @notice Zap token to single asset Treasury Bill
    /// @param inputToken Input token to zap
    /// @param inputAmount Amount of input tokens to zap
    /// @param path Path from input token to stake token
    /// @param minAmountsSwap The minimum amount of output tokens that must be received for swap
    /// @param deadline Unix timestamp after which the transaction will revert
    /// @param bill Pool address
    /// @param maxPrice MaxPrice for purchasing a bill
    function zapSingleAssetTBill(
        IERC20 inputToken,
        uint256 inputAmount,
        address[] calldata path,
        uint256 minAmountsSwap,
        uint256 deadline,
        ICustomBill bill,
        uint256 maxPrice
    ) external nonReentrant {
        inputAmount = _transferIn(inputToken, inputAmount);
        _zapSingleAssetTBill(inputToken, inputAmount, path, minAmountsSwap, deadline, bill, maxPrice);
    }

    /// @notice Zap native token to single asset Treasury Bill
    /// @param path Path from input token to stake token
    /// @param minAmountsSwap The minimum amount of output tokens that must be received for swap
    /// @param deadline Unix timestamp after which the transaction will revert
    /// @param bill Pool address
    /// @param maxPrice MaxPrice for purchasing a bill
    function zapSingleAssetTBillNative(
        address[] calldata path,
        uint256 minAmountsSwap,
        uint256 deadline,
        ICustomBill bill,
        uint256 maxPrice
    ) external payable nonReentrant {
        (IERC20 weth, uint256 inputAmount) = _wrapNative();
        _zapSingleAssetTBill(weth, inputAmount, path, minAmountsSwap, deadline, bill, maxPrice);
    }

    /** INTERNAL FUNCTIONs **/

    /// @notice Zap token to single asset Treasury Bill
    /// @param inputToken Input token to zap
    /// @param inputAmount Amount of input tokens to zap
    /// @param path Path from input token to stake token
    /// @param minAmountsSwap The minimum amount of output tokens that must be received for swap
    /// @param deadline Unix timestamp after which the transaction will revert
    /// @param bill Pool address
    /// @param maxPrice MaxPrice for purchasing a bill
    function _zapSingleAssetTBill(
        IERC20 inputToken,
        uint256 inputAmount,
        address[] calldata path,
        uint256 minAmountsSwap,
        uint256 deadline,
        ICustomBill bill,
        uint256 maxPrice
    ) internal {
        IERC20 principalToken = IERC20(bill.principalToken());
        require(
            (address(inputToken) == path[0] && address(principalToken) == path[path.length - 1]),
            "ApeSwapZapTBills: Wrong path for inputToken or principalToken"
        );

        _routerSwap(inputAmount, minAmountsSwap, path, deadline, true);
        (uint256 depositAmount, uint256 payoutAmount) = _depositTBill(bill, principalToken, maxPrice, msg.sender);

        emit ZapTBill(bill, principalToken, depositAmount, payoutAmount);
    }

    /** INTERNAL FUNCTIONS **/

    function _depositTBill(
        ICustomBill bill,
        IERC20 principalToken,
        uint256 maxPrice,
        address depositor
    ) internal returns (uint256 depositAmount, uint256 payoutAmount) {
        depositAmount = principalToken.balanceOf(address(this));
        require(depositAmount > 0, "ApeSwapZapTBills: Nothing to deposit");
        principalToken.approve(address(bill), depositAmount);
        payoutAmount = bill.deposit(depositAmount, maxPrice, depositor);
        principalToken.approve(address(bill), 0);
    }

    function _validateTBillZap(
        address[] memory lpTokens,
        ICustomBill bill
    ) internal view returns (IApePair principalToken) {
        principalToken = IApePair(bill.principalToken());
        require(
            (lpTokens[0] == principalToken.token0() && lpTokens[1] == principalToken.token1()) ||
                (lpTokens[1] == principalToken.token0() && lpTokens[0] == principalToken.token1()),
            "ApeSwapZapTBills: Wrong LP pair for TBill"
        );
    }
}