// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./interfaces/IPancakeRouter02.sol";
import "./interfaces/IUniswapV3SwapRouter.sol";
import "./interfaces/IPeripheryState.sol";
import "./libraries/IWETH9.sol";
import "./libraries/Order.sol";
import "./libraries/FullMath.sol";

abstract contract ExternalSwapRouterUpgradeable is Initializable {
    using SafeERC20 for IERC20;

    address public pancakeswapRouter; // legacy variable, not removing it just to maintain the storage layout of upgradable contract
    // https://docs.pancakeswap.finance/developers/smart-contracts/pancakeswap-exchange/v2-contracts/router-v2
    address public constant PANCAKESWAP_ROUTER_ADDRESS = 0xEfF92A263d31888d860bD50809A8D171709b7b1c;

    // https://docs.uniswap.org/contracts/v3/reference/deployments
    address public constant UNISWAP_V3_ROUTER_ADDRESS = 0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45;

    // different for each chain need to update accordingly
    address public constant ONE_INCH_ROUTER_ADDRESS = 0x1111111254EEB25477B68fb85Ed929f73A960582;

    event SwapPancake(
        address indexed sender,
        address indexed recipient,
        address tokenIn,
        address tokenOut,
        int256 amountIn,
        int256 amountOut,
        bytes16 quoteId
    );

    event SwapUniswapV3(
        address indexed sender,
        address indexed recipient,
        address tokenIn,
        address tokenOut,
        int256 amountIn,
        int256 amountOut,
        bytes16 quoteId
    );

    event Swap1inch(
        address indexed sender,
        address indexed recipient,
        address tokenIn,
        address tokenOut,
        int256 amountIn,
        int256 amountOut,
        bytes16 quoteId
    );

    error InvalidFunctionSelectorInCalldata(bytes4);
    error OrderExpired();
    error ZeroFlexibleAmount();
    error InvalidZeroAddressInput();
    error SellerAmountTooLargeOverflow(uint);
    error BuyerAmountTooLargeOverflow(uint);
    error ExternalCallFailed(bytes);
    error InvalidZeroInputAmout();

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function handleEthCase(address tokenIn, address payer, uint256 tokenAmount) internal {
        address weth9 = IPeripheryState(address(this)).WETH9();
        if (tokenIn == weth9 && address(this).balance >= tokenAmount) {
            IWETH9(weth9).deposit{value: tokenAmount}();
        } else if (payer != address(this)) {
            IERC20(tokenIn).safeTransferFrom(payer, address(this), tokenAmount);
        }
    }

    function swapPancake(
        Orders.Order memory order,
        uint256 flexibleAmount,
        address recipient,
        address payer
    ) internal returns (int256, int256) {
        if (order.deadlineTimestamp <= block.timestamp) {
            revert OrderExpired();
        }
        if (flexibleAmount == 0) {
            revert ZeroFlexibleAmount();
        }

        (uint256 buyerTokenAmount, uint256 sellerTokenAmount) = calculateTokenAmount(flexibleAmount, order);

        handleEthCase(order.sellerToken, payer, sellerTokenAmount);

        IERC20(order.sellerToken).safeApprove(PANCAKESWAP_ROUTER_ADDRESS, sellerTokenAmount);

        uint[] memory outputAmounts;
        {
            address[] memory path = new address[](2);
            path[0] = order.sellerToken;
            path[1] = order.buyerToken;

            if (sellerTokenAmount > uint256(type(int256).max)) {
                revert SellerAmountTooLargeOverflow(sellerTokenAmount);
            }

            outputAmounts = IPancakeRouter02(PANCAKESWAP_ROUTER_ADDRESS).swapExactTokensForTokens(
                sellerTokenAmount,
                buyerTokenAmount,
                path,
                recipient,
                order.deadlineTimestamp
            );
        }

        if (outputAmounts[outputAmounts.length - 1] > uint256(type(int256).max)) {
            revert BuyerAmountTooLargeOverflow(outputAmounts[outputAmounts.length - 1]);
        }

        emit SwapPancake(
            order.caller,
            recipient,
            order.sellerToken,
            order.buyerToken,
            int256(sellerTokenAmount),
            (-1 * int256(outputAmounts[outputAmounts.length - 1])),
            order.quoteId
        );

        return ((-1 * int256(outputAmounts[outputAmounts.length - 1])), int256(sellerTokenAmount));
    }

    function swapUniswapV3(
        Orders.Order memory order,
        uint256 flexibleAmount,
        address recipient,
        address payer,
        uint24 feeTier
    ) internal returns (int256, int256) {
        if (order.deadlineTimestamp <= block.timestamp) {
            revert OrderExpired();
        }
        if (flexibleAmount == 0) {
            revert ZeroFlexibleAmount();
        }

        uint256 sellerTokenAmount;
        uint256 amountOut;
        {
            uint256 buyerTokenAmount;
            (buyerTokenAmount, sellerTokenAmount) = calculateTokenAmount(flexibleAmount, order);

            handleEthCase(order.sellerToken, payer, sellerTokenAmount);

            IERC20(order.sellerToken).safeApprove(UNISWAP_V3_ROUTER_ADDRESS, sellerTokenAmount);

            if (sellerTokenAmount > uint256(type(int256).max)) {
                revert SellerAmountTooLargeOverflow(sellerTokenAmount);
            }

            amountOut = IUniswapV3SwapRouter(UNISWAP_V3_ROUTER_ADDRESS).exactInputSingle(
                IUniswapV3SwapRouter.ExactInputSingleParams({
                    tokenIn: order.sellerToken,
                    tokenOut: order.buyerToken,
                    fee: feeTier,
                    recipient: recipient,
                    amountIn: sellerTokenAmount,
                    amountOutMinimum: buyerTokenAmount,
                    sqrtPriceLimitX96: 0
                })
            );
        }

        if (amountOut > uint256(type(int256).max)) {
            revert BuyerAmountTooLargeOverflow(amountOut);
        }

        emit SwapUniswapV3(
            order.caller,
            recipient,
            order.sellerToken,
            order.buyerToken,
            int256(sellerTokenAmount),
            (-1 * int256(amountOut)),
            order.quoteId
        );

        return ((-1 * int256(amountOut)), int256(sellerTokenAmount));
    }

    struct OneInchSwapDescription {
        IERC20 srcToken;
        IERC20 dstToken;
        address payable srcReceiver;
        address payable dstReceiver;
        uint256 amount;
        uint256 minReturnAmount;
        uint256 flags;
    }

    function swap1inch(
        Orders.Order memory order,
        uint256 flexibleAmount,
        address recipient,
        address payer,
        bytes memory fallbackSwapCalldata
    ) internal returns (int256, int256) {
        if (order.deadlineTimestamp <= block.timestamp) {
            revert OrderExpired();
        }
        if (flexibleAmount == 0) {
            revert ZeroFlexibleAmount();
        }

        (uint256 buyerTokenAmount, uint256 sellerTokenAmount) = calculateTokenAmount(flexibleAmount, order);

        handleEthCase(order.sellerToken, payer, sellerTokenAmount);

        IERC20(order.sellerToken).safeApprove(ONE_INCH_ROUTER_ADDRESS, sellerTokenAmount);

        if (sellerTokenAmount > uint256(type(int256).max)) {
            revert SellerAmountTooLargeOverflow(sellerTokenAmount);
        }

        uint256 amountOut;

        {
            bytes memory functionParams;
            assembly {
                functionParams := add(fallbackSwapCalldata, 4) // exlucde the function seletor
            }

            // function signatures and input
            /*
            0x12aa3caf: swap
            function swap(
                IAggregationExecutor executor,
                SwapDescription calldata desc,
                bytes calldata permit,
                bytes calldata data
            )
            */
            /**
            0xe449022e: uniswapV3Swap
            function uniswapV3Swap(
                uint256 amount,
                uint256 minReturn,
                uint256[] calldata pools
            )
            */
            /**
            0x0502b1c5: unoswap
            function unoswap(
                IERC20 srcToken,
                uint256 amount,
                uint256 minReturn,
                uint256[] calldata pools
            )
            */
            // 0x62e238bb: fillOrder            require signature, cannot change input amount
            // 0x3eca9c0a: fillOrderRFQ         require signature, cannot change input amount
            // 0x84bd6d29: clipperSwap          require signature, cannot change input amount
            // 0x9570eeee: fillOrderRFQCompact  require signature, cannot change input amount
            if (bytes4(fallbackSwapCalldata) == bytes4(0x12aa3caf)) {
                {
                    (address executor, OneInchSwapDescription memory desc, bytes memory permit, bytes memory data) = abi
                        .decode(functionParams, (address, OneInchSwapDescription, bytes, bytes));
                    desc.amount = sellerTokenAmount;
                    desc.minReturnAmount = buyerTokenAmount;
                    fallbackSwapCalldata = abi.encodeWithSelector(bytes4(0x12aa3caf), executor, desc, permit, data);
                }
            } else if (bytes4(fallbackSwapCalldata) == bytes4(0xe449022e)) {
                {
                    (, , uint256[] memory pools) = abi.decode(
                        functionParams,
                        (uint256, uint256, uint256[])
                    );
                    fallbackSwapCalldata = abi.encodeWithSelector(bytes4(0xe449022e), sellerTokenAmount, buyerTokenAmount, pools);
                }
            } else if (bytes4(fallbackSwapCalldata) == bytes4(0x0502b1c5)) {
                {
                    (address srcToken, , , uint256[] memory pools) = abi.decode(
                        functionParams,
                        (address, uint256, uint256, uint256[])
                    );
                    fallbackSwapCalldata = abi.encodeWithSelector(bytes4(0x0502b1c5), srcToken, sellerTokenAmount, buyerTokenAmount, pools);
                }
            } else if (
                bytes4(fallbackSwapCalldata) == bytes4(0x62e238bb) ||
                bytes4(fallbackSwapCalldata) == bytes4(0x3eca9c0a) ||
                bytes4(fallbackSwapCalldata) == bytes4(0x84bd6d29) ||
                bytes4(fallbackSwapCalldata) == bytes4(0x9570eeee)
            ) {
                // cannot change input amount as it requires signature in the input
            } else {
                revert InvalidFunctionSelectorInCalldata(bytes4(fallbackSwapCalldata));
            }

            (bool success, bytes memory result) = ONE_INCH_ROUTER_ADDRESS.call(fallbackSwapCalldata);
            if (!success) {
                revert ExternalCallFailed(result);
            }

            IERC20(order.sellerToken).safeApprove(ONE_INCH_ROUTER_ADDRESS, 0);

            // * as desired return value
            // function signatures
            // 0x12aa3caf: swap                 - returns (uint256 returnAmount*, uint256 spentAmount)
            // 0xe449022e: uniswapV3Swap        - returns (uint256 returnAmount*)
            // 0x0502b1c5: unoswap              - returns (uint256 returnAmount*)
            // 0x84bd6d29: clipperSwap          - returns (uint256 returnAmount*)
            // 0x62e238bb: fillOrder            - returns (uint256 actualMakingAmount*, uint256 actualTakingAmount, bytes32 orderHash)
            // 0x3eca9c0a: fillOrderRFQ         - returns (uint256 filledMakingAmount*, uint256 filledTakingAmount, bytes32 orderHash)
            // 0x9570eeee: fillOrderRFQCompact  - returns (uint256 filledMakingAmount*, uint256 filledTakingAmount, bytes32 orderHash)
            if (bytes4(fallbackSwapCalldata) == bytes4(0x12aa3caf)) {
                {
                    (uint256 returnAmount, ) = abi.decode(result, (uint256, uint256));
                    amountOut = returnAmount;
                }
            } else if (
                bytes4(fallbackSwapCalldata) == bytes4(0xe449022e) ||
                bytes4(fallbackSwapCalldata) == bytes4(0x0502b1c5) ||
                bytes4(fallbackSwapCalldata) == bytes4(0x84bd6d29)
            ) {
                {
                    uint256 returnAmount = abi.decode(result, (uint256));
                    amountOut = returnAmount;
                }
            } else if (
                bytes4(fallbackSwapCalldata) == bytes4(0x62e238bb) ||
                bytes4(fallbackSwapCalldata) == bytes4(0x3eca9c0a) ||
                bytes4(fallbackSwapCalldata) == bytes4(0x9570eeee)
            ) {
                {
                    (uint256 returnAmount, , ) = abi.decode(result, (uint256, uint256, bytes32));
                    amountOut = returnAmount;
                }
            } else {
                revert InvalidFunctionSelectorInCalldata(bytes4(fallbackSwapCalldata));
            }
        }

        if (amountOut > uint256(type(int256).max)) {
            revert BuyerAmountTooLargeOverflow(amountOut);
        }

        if (recipient != address(this)) {
            IERC20(order.buyerToken).safeTransfer(recipient, amountOut);
        }

        emitSwap1Inch(order, recipient, sellerTokenAmount, amountOut);

        return ((-1 * int256(amountOut)), int256(sellerTokenAmount));
    }

    function emitSwap1Inch(Orders.Order memory order, address recipient, uint256 sellerTokenAmount, uint256 amountOut) internal {
        emit Swap1inch(
            order.caller,
            recipient,
            order.sellerToken,
            order.buyerToken,
            int256(sellerTokenAmount),
            (-1 * int256(amountOut)),
            order.quoteId
        );
    }

    function calculateTokenAmount(
        uint256 flexibleAmount,
        Orders.Order memory _order
    ) private pure returns (uint256, uint256) {
        uint256 buyerTokenAmount;
        uint256 sellerTokenAmount;

        sellerTokenAmount = flexibleAmount >= _order.sellerTokenAmount ? _order.sellerTokenAmount : flexibleAmount;

        if (_order.sellerTokenAmount <= 0 || _order.buyerTokenAmount <= 0) {
            revert InvalidZeroInputAmout();
        }

        buyerTokenAmount = FullMath.mulDiv(sellerTokenAmount, _order.buyerTokenAmount, _order.sellerTokenAmount);
        if (sellerTokenAmount <= 0) {
            revert InvalidZeroInputAmout();
        }
        return (buyerTokenAmount, sellerTokenAmount);
    }

    uint256[49] private __gap;
}