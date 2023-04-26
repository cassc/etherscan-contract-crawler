// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;
pragma abicoder v2;

import "./interfaces/INativeRouter.sol";
import "./interfaces/INativePool.sol";
import "./interfaces/INativePoolFactory.sol";
import "./libraries/SafeCast.sol";
import "./libraries/CallbackValidation.sol";
import "./libraries/Order.sol";
import "./libraries/PeripheryPayments.sol";
import "./libraries/TransferHelper.sol";
import "./libraries/Multicall.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";
import "./storage/NativeRouterStorage.sol";
import "./ExternalSwapRouterUpgradeable.sol";

contract NativeRouter is
    INativeRouter,
    PeripheryPayments,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable,
    EIP712Upgradeable,
    Multicall,
    NativeRouterStorage,
    PausableUpgradeable,
    ExternalSwapRouterUpgradeable
{
    using Orders for bytes;
    using SafeCast for uint256;
    uint public constant TEN_THOUSAND_DENOMINATOR = 10000;
    bytes32 private constant WIDGET_FEE_SIGNATURE_HASH =
        keccak256("WidgetFee(address signer,address feeRecipient,uint256 feeRate)");

    struct SwapCallbackData {
        bytes orders;
        address payer;
    }

    event SwapCalculations(uint256 amountIn, address recipient);

    function initialize(
        address factory,
        address weth9,
        address _widgetFeeSigner,
        address pancakeswapRouter
    ) public initializer {
        initializeState(factory, weth9);
        __EIP712_init("native router", "1");
        __ReentrancyGuard_init();
        __Ownable_init();
        __UUPSUpgradeable_init();
        setWidgetFeeSigner(_widgetFeeSigner);
        __Pausable_init();
        __ExternalSwapRouter_init(pancakeswapRouter);
    }

    function getImplementation() public view returns (address) {
        return _getImplementation();
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function setWeth9Unwrapper(address payable _weth9Unwrapper) public override onlyOwner {
        require(_weth9Unwrapper != address(0), "zero address input");
        weth9Unwrapper = _weth9Unwrapper;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function setPancakeswapRouter(address _pancakeswapRouter) external onlyOwner {
        _setPancakeswapRouter(_pancakeswapRouter);
    }

    function setWidgetFeeSigner(address _widgetFeeSigner) public onlyOwner {
        require(
            _widgetFeeSigner != address(0),
            "Widget fee signer address specified should not be zero address"
        );
        widgetFeeSigner = _widgetFeeSigner;
        emit SetWidgetFeeSigner(widgetFeeSigner);
    }

    function swapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata _data
    ) external override whenNotPaused {
        require(amount0Delta > 0 || amount1Delta > 0, "Delta is negative");
        SwapCallbackData memory data = abi.decode(_data, (SwapCallbackData));

        (Orders.Order memory order, ) = data.orders.decodeFirstOrder();
        require(msg.sender == order.buyer, "callback is not from order buyer");

        CallbackValidation.verifyCallback(factory, order.buyer);

        uint256 amountToPay = amount0Delta < 0 ? uint256(amount1Delta) : uint256(amount0Delta);
        pay(order.sellerToken, data.payer, msg.sender, amountToPay);
    }

    function exactInputSingle(
        ExactInputSingleParams memory params
    ) external payable override nonReentrant whenNotPaused returns (uint256 amountOut) {
        require(!params.orders.hasMultiplePools(), "exactInputSingle: multiple orders");
        require(
            verifyWidgetFeeSignature(params.widgetFee, params.widgetFeeSignature),
            "widget fee signature is invalid"
        );
        require(params.widgetFee.feeRate <= TEN_THOUSAND_DENOMINATOR, "invalid widget fee");
        bool hasAlreadyPaid;
        (Orders.Order memory order, ) = params.orders.decodeFirstOrder();
        if (params.amountIn == 0) {
            hasAlreadyPaid = true;
            params.amountIn = IERC20(order.sellerToken).balanceOf(address(this));
        }
        require(order.seller == msg.sender, "seller is not correct");

        uint widgetFeeAmount = (params.amountIn * params.widgetFee.feeRate) /
            TEN_THOUSAND_DENOMINATOR;

        if (msg.value > 0 && order.sellerToken == WETH9) {
            TransferHelper.safeTransferETH(params.widgetFee.feeRecipient, widgetFeeAmount);
            emit WidgetFeeTransfer(
                params.widgetFee.feeRecipient,
                params.widgetFee.feeRate,
                widgetFeeAmount,
                address(0)
            );
        } else {
            TransferHelper.safeTransferFrom(
                order.sellerToken,
                msg.sender,
                params.widgetFee.feeRecipient,
                widgetFeeAmount
            );
            emit WidgetFeeTransfer(
                params.widgetFee.feeRecipient,
                params.widgetFee.feeRate,
                widgetFeeAmount,
                order.sellerToken
            );
        }

        params.amountIn -= widgetFeeAmount;
        emit SwapCalculations(params.amountIn, params.recipient);

        amountOut = exactInputInternal(
            params.amountIn,
            params.recipient,
            SwapCallbackData({
                orders: params.orders,
                payer: hasAlreadyPaid ? address(this) : msg.sender
            })
        );
        require(amountOut >= params.amountOutMinimum, "Too little received");

        if (address(this).balance > 0)
            TransferHelper.safeTransferETH(msg.sender, address(this).balance);
    }

    /// @inheritdoc INativeRouter
    function exactInput(
        ExactInputParams memory params
    ) external payable override nonReentrant whenNotPaused returns (uint256 amountOut) {
        require(
            verifyWidgetFeeSignature(params.widgetFee, params.widgetFeeSignature),
            "widget fee signature is invalid"
        );
        require(params.widgetFee.feeRate <= 10000, "invalid widget fee");
        bool hasAlreadyPaid;
        (Orders.Order memory order, ) = params.orders.decodeFirstOrder();
        if (params.amountIn == 0) {
            hasAlreadyPaid = true;
            params.amountIn = IERC20(order.sellerToken).balanceOf(address(this));
        }
        require(order.seller == msg.sender, "seller is not correct");

        address payer = hasAlreadyPaid ? address(this) : msg.sender;

        uint widgetFeeAmount = (params.amountIn * params.widgetFee.feeRate) /
            TEN_THOUSAND_DENOMINATOR;
        if (msg.value > 0 && order.sellerToken == WETH9) {
            TransferHelper.safeTransferETH(params.widgetFee.feeRecipient, widgetFeeAmount);
            emit WidgetFeeTransfer(
                params.widgetFee.feeRecipient,
                params.widgetFee.feeRate,
                widgetFeeAmount,
                address(0)
            );
        } else {
            TransferHelper.safeTransferFrom(
                order.sellerToken,
                msg.sender,
                params.widgetFee.feeRecipient,
                widgetFeeAmount
            );
            emit WidgetFeeTransfer(
                params.widgetFee.feeRecipient,
                params.widgetFee.feeRate,
                widgetFeeAmount,
                order.sellerToken
            );
        }

        params.amountIn -= widgetFeeAmount;

        while (true) {
            bool hasMultiplePools = params.orders.hasMultiplePools();
            // the outputs of prior swaps become the inputs to subsequent ones
            params.amountIn = exactInputInternal(
                params.amountIn,
                hasMultiplePools ? address(this) : params.recipient,
                SwapCallbackData({
                    orders: params.orders.getFirstOrder(), // only the first pool in the path is necessary
                    payer: payer
                })
            );

            // decide whether to continue or terminate
            if (hasMultiplePools) {
                payer = address(this);
                params.orders = params.orders.skipOrder();
            } else {
                amountOut = params.amountIn;
                break;
            }
        }

        require(amountOut >= params.amountOutMinimum, "Too little received");

        if (address(this).balance > 0)
            TransferHelper.safeTransferETH(msg.sender, address(this).balance);
    }

    // private methods
    /// @dev Performs a single exact input swap
    function exactInputInternal(
        uint256 amountIn,
        address recipient,
        SwapCallbackData memory data
    ) private returns (uint256 amountOut) {
        (Orders.Order memory order, bytes memory signature) = data.orders.decodeFirstOrder();
        require(order.txOrigin == tx.origin, "txOrigin is wrong");

        int256 amount0Delta;
        int256 amount1Delta;
        if (INativePoolFactory(factory).verifyPool(order.buyer)) {
            (amount0Delta, amount1Delta) = INativePool(order.buyer).swap(
                abi.encode(order),
                signature,
                amountIn,
                recipient,
                abi.encode(data)
            );
        } else if (order.buyer == pancakeswapRouter) {
            (amount0Delta, amount1Delta) = swapPancake(order, amountIn, recipient);
        } else {
            revert("invalid order buyer");
        }
        return uint256(-(amount0Delta > 0 ? amount1Delta : amount0Delta));
    }

    function getWidgetFeeMessageHash(
        WidgetFee memory widgetFeeData
    ) internal pure returns (bytes32) {
        bytes32 hash = keccak256(
            abi.encode(
                WIDGET_FEE_SIGNATURE_HASH,
                widgetFeeData.signer,
                widgetFeeData.feeRecipient,
                widgetFeeData.feeRate
            )
        );
        return hash;
    }

    function verifyWidgetFeeSignature(
        WidgetFee memory widgetFeeData,
        bytes memory signature
    ) internal view returns (bool) {
        require(widgetFeeData.signer == widgetFeeSigner, "Signer is invalid");
        bytes32 digest = _hashTypedDataV4(getWidgetFeeMessageHash(widgetFeeData));

        address recoveredSigner = ECDSAUpgradeable.recover(digest, signature);
        return widgetFeeData.signer == recoveredSigner;
    }
}