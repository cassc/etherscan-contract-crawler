// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../oracles/Oracle.sol";

import "../libraries/external/FullMath.sol";
import "./swapper-callbacks/ICoefficientCallback.sol";

import "./DefaultAccessControl.sol";

contract Swapper is DefaultAccessControl, ReentrancyGuard {
    error LimitUnderflow();
    error LimitOverflow();
    error CallbackFailed();
    error OrderNotFinalized();
    error InvalidIndex();

    using SafeERC20 for IERC20;

    struct Pair {
        address tokenIn;
        address tokenOut;
    }

    /// @dev When creating an order, pushInfoIndex == UINT256_MAX, which means that the order has not been processed yet.
    /// @dev In the process of calling the pushOrders function, this value may change.
    /// @dev If pushInfoIndex == 0, then the order is expired,
    /// @dev otherwise it is the position in 1-indexing in the pushInfo array with information about the execution of the pushOrders function.
    struct Order {
        address sender;
        uint256 amountIn;
        uint256 minPriceX96;
        uint256 deadline;
        uint256 pushInfoIndex;
        Pair pair;
    }

    struct PushInfo {
        uint256 totalAmountIn;
        uint256 totalAmountOut;
    }

    struct OracleParams {
        Oracle oracle;
        address[] tokens;
        bytes[] securityParams;
    }

    uint256 public constant Q96 = 2 ** 96;

    mapping(bytes32 => uint256[]) public activeOrders;
    Order[] public orders;
    PushInfo[] public pushInfo;
    uint256 public maxExpiringTime;
    ICoefficientCallback public coefficientCallback;

    OracleParams private _oracleParams;

    function getOrders(address user) public view returns (Order[] memory userOrders) {
        uint256 numberOfOrders = 0;
        for (uint256 i = 0; i < orders.length; i++) {
            if (orders[i].sender == user) {
                numberOfOrders++;
            }
        }
        uint256 iterator = 0;
        userOrders = new Order[](numberOfOrders);
        for (uint256 i = 0; i < orders.length; i++) {
            if (orders[i].sender == user) {
                userOrders[iterator] = orders[i];
                iterator++;
            }
        }
    }

    function oracleParams()
        public
        view
        returns (Oracle oracle, address[] memory tokens, bytes[] memory securityParams)
    {
        OracleParams memory oracleParams_ = _oracleParams;
        oracle = oracleParams_.oracle;
        tokens = oracleParams_.tokens;
        securityParams = oracleParams_.securityParams;
    }

    constructor(address admin) DefaultAccessControl(admin) {}

    function updateOracleParams(OracleParams memory oracleParams_) external {
        _requireAdmin();
        _oracleParams = oracleParams_;
    }

    function updateMaxExpiringTime(uint256 maxExpiringTime_) external {
        _requireAdmin();
        maxExpiringTime = maxExpiringTime_;
    }

    function updateCoefficientCallback(ICoefficientCallback coefficientCallback_) external {
        _requireAdmin();
        coefficientCallback = coefficientCallback_;
    }

    /// @dev User requests to swap the amountIn of the pair.tokenIn token to the pair.tokenOut token.
    /// @dev The order deadline is current timestamp + expiringTime
    /// @dev The minimum auction coefficient is minCoefficient.
    /// @param pair token to be swapped and token to be received
    /// @param amountIn amount of tokenIn to be swapped
    /// @param minAmountOut the minimum amount out tokenOut
    /// @param expiringTime maximum waiting time for order execution
    /// @return orderId unique identificator of the order
    function makeOrder(
        Pair memory pair,
        uint256 amountIn,
        uint256 minAmountOut,
        uint256 expiringTime
    ) external nonReentrant returns (uint256 orderId) {
        if (expiringTime > maxExpiringTime) revert LimitOverflow();
        IERC20(pair.tokenIn).safeTransferFrom(msg.sender, address(this), amountIn);
        uint256 minPriceX96 = FullMath.mulDivRoundingUp(minAmountOut, Q96, amountIn);
        Order memory order = Order({
            sender: msg.sender,
            amountIn: amountIn,
            minPriceX96: minPriceX96,
            deadline: block.timestamp + expiringTime,
            pushInfoIndex: type(uint256).max,
            pair: pair
        });
        orderId = orders.length;
        orders.push(order);
        activeOrders[keccak256(abi.encode(pair))].push(orderId);
    }

    /// @dev In case of a successful swap, the user can collect the pair.tokenOut token by calling the claimTokens function.
    /// @dev If more than expiringTime has passed since the order was placed,
    /// @dev then calling the function will transfer the tokenIn to the requested address
    /// @param pair token to be swapped and token to be received
    /// @param orderId unique identificator of the order
    function claimTokens(Pair memory pair, uint256 orderId) external nonReentrant {
        _claim(pair, orderId, msg.sender);
    }

    /// @dev In case of a successful swap, the user can collect the pair.tokenOut token by calling the claimTokens function.
    /// @dev If more than expiringTime has passed since the order was placed,
    /// @dev then calling the function will transfer the tokenIn to the requested address
    /// @dev additionally user can specify address where token will be transferred
    /// @param pair token to be swapped and token to be received
    /// @param orderId unique identificator of the order
    /// @param to the address that will receive the token
    function claimTokens(Pair memory pair, uint256 orderId, address to) external nonReentrant {
        _claim(pair, orderId, to);
    }

    function _claim(Pair memory pair, uint256 orderId, address to) private {
        if (orderId >= orders.length) revert InvalidIndex();
        Order storage order = orders[orderId];
        uint256 amountIn = order.amountIn;
        if (order.sender != msg.sender || amountIn == 0) revert Forbidden();
        uint256 pushInfoIndex = order.pushInfoIndex;
        if (pushInfoIndex == 0) {
            IERC20(pair.tokenIn).safeTransfer(to, amountIn);
        } else if (pushInfoIndex == type(uint256).max) {
            if (order.deadline > block.timestamp) {
                IERC20(pair.tokenIn).safeTransfer(to, amountIn);
                order.pushInfoIndex = 0;
            } else {
                revert OrderNotFinalized();
            }
        } else {
            PushInfo memory pushInfo_ = pushInfo[pushInfoIndex - 1];
            uint256 amountOut = FullMath.mulDiv(pushInfo_.totalAmountOut, amountIn, pushInfo_.totalAmountIn);
            IERC20(pair.tokenOut).safeTransfer(to, amountOut);
        }
        order.amountIn = 0;
    }

    /// @dev Function for closing an order. If the order has already been filled, or more time has passed since the request than expiringTime,
    /// @dev or the order has already been closed, then the function will fail with an error
    /// @param pair token to be swapped and token to be received
    /// @param orderId unique identificator of the order
    function close(Pair memory pair, uint256 orderId) external nonReentrant {
        _close(pair, orderId, msg.sender);
    }

    /// @dev Function for closing an order. If the order has already been filled, or more time has passed since the request than expiringTime,
    /// @dev or the order has already been closed, then the function will fail with an error
    /// @dev additionally user can specify address where token will be transferred
    /// @param pair token to be swapped and token to be received
    /// @param orderId unique identificator of the order
    /// @param to the address that will receive the token
    function close(Pair memory pair, uint256 orderId, address to) external nonReentrant {
        _close(pair, orderId, to);
    }

    function _close(Pair memory pair, uint256 orderId, address to) private {
        if (orderId >= orders.length) revert InvalidIndex();
        Order storage order = orders[orderId];
        uint256 amountIn = order.amountIn;
        if (order.sender != msg.sender || amountIn == 0 || order.pushInfoIndex != type(uint256).max) revert Forbidden();
        IERC20(pair.tokenIn).safeTransfer(to, amountIn);
        order.amountIn = 0;
        order.pushInfoIndex = 0;
    }

    /// @dev the function returns the oracle value of the given `amount` of the `token` in the last token of the OracleParams::tokens array.
    function getPrice(address token, uint256 amount) public view returns (uint256) {
        OracleParams memory oracleParams_ = _oracleParams;
        uint256 tokenIndex = type(uint256).max;
        for (uint256 i = 0; i < oracleParams_.tokens.length; i++) {
            if (oracleParams_.tokens[i] == token) {
                tokenIndex = i;
                break;
            }
        }

        address[] memory tokens;
        uint256[] memory tokenAmounts;
        bytes[] memory securityParams;
        if (tokenIndex == type(uint256).max) {
            tokens = new address[](oracleParams_.tokens.length + 1);
            tokens[0] = token;
            tokenAmounts = new uint256[](oracleParams_.tokens.length + 1);
            tokenAmounts[0] = amount;
            securityParams = new bytes[](oracleParams_.tokens.length + 1);

            for (uint256 i = 0; i < oracleParams_.tokens.length; i++) {
                tokens[i + 1] = oracleParams_.tokens[i];
                securityParams[i + 1] = oracleParams_.securityParams[i];
            }
        } else {
            tokens = oracleParams_.tokens;
            tokenAmounts = new uint256[](tokens.length);
            tokenAmounts[tokenIndex] = amount;
            securityParams = oracleParams_.securityParams;
        }

        return oracleParams_.oracle.quote(tokens, tokenAmounts, securityParams);
    }

    /// @dev Function, that for the given parameters of the pair and the size of the batch, calls the callback
    /// @dev in which the tokenIn to tokenOut swap occurs.
    /// @dev If during the swap, the callback returns an insufficient number of tokens according to the oracles' assessment and the current auction coefficient,
    /// @dev then the function will fail with a LimitUnderflow error.
    /// @dev The callback is supposed to determine the number of tokens to swap using the ERC20::allowance(swapper, callback) function.
    function pushOrders(
        Pair memory pair,
        uint256 batchSize,
        address callback,
        bytes memory data
    ) external nonReentrant {
        uint256 coefficientX96 = coefficientCallback.calculateCoefficientX96();
        uint256 priceX96 = FullMath.mulDivRoundingUp(getPrice(pair.tokenIn, Q96), Q96, getPrice(pair.tokenOut, Q96));
        priceX96 = FullMath.mulDivRoundingUp(priceX96, coefficientX96, Q96);
        uint256[] storage activeOrders_ = activeOrders[keccak256(abi.encode(pair))];
        uint256 length = activeOrders_.length;
        uint256 totalAmountIn = 0;
        unchecked {
            uint256 pushInfoIndex = pushInfo.length + 1;
            uint256 processedNumber = 0;
            uint256 blockTimestamp = block.timestamp;
            for (uint256 i = 0; i < length; i++) {
                uint256 orderId = activeOrders_[i];
                Order storage order = orders[orderId];
                /// @dev remove all overdue orders from the array of active orders
                while (order.deadline < blockTimestamp && i < length) {
                    order.pushInfoIndex = 0;
                    --length;
                    orderId = activeOrders_[length];
                    activeOrders_[i] = orderId;
                    order = orders[orderId];
                    activeOrders_.pop();
                }

                if (i == length) break;
                if (order.minPriceX96 > priceX96) {
                    continue;
                }

                processedNumber++;
                totalAmountIn += order.amountIn;

                /// @dev implicitly execute the order by specifying the corresponding index in the array of pushes
                {
                    order.pushInfoIndex = pushInfoIndex;
                    --length;
                    orderId = activeOrders_[length];
                    activeOrders_[i] = orderId;
                    order = orders[orderId];
                    activeOrders_.pop();
                }

                if (processedNumber == batchSize) break;

                /// @dev Since the executed order at the previous step was removed from the array of active orders,
                /// @dev we shift the iterator back. There will be no underflow due to `unchecked`
                --i;
            }
            if (processedNumber == 0) return;
        }

        {
            IERC20(pair.tokenIn).safeIncreaseAllowance(callback, totalAmountIn);
            uint256 balanceBefore = IERC20(pair.tokenOut).balanceOf(address(this));

            (bool success, ) = callback.call(data);
            if (!success) revert CallbackFailed();

            if (IERC20(pair.tokenIn).allowance(address(this), callback) != 0) {
                IERC20(pair.tokenIn).safeApprove(callback, 0);
            }
            uint256 totalAmountOut = IERC20(pair.tokenOut).balanceOf(address(this)) - balanceBefore;
            if (FullMath.mulDivRoundingUp(totalAmountIn, priceX96, Q96) > totalAmountOut) {
                revert LimitUnderflow();
            }
            pushInfo.push(PushInfo({totalAmountIn: totalAmountIn, totalAmountOut: totalAmountOut}));
        }

        IERC20(pair.tokenIn).safeApprove(callback, 0);
    }
}