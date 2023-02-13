// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "../lib/interfaces/token/IERC20.sol";
import "./ConveyorErrors.sol";
import "./interfaces/ISandboxLimitOrderBook.sol";
import "../lib/libraries/token/SafeERC20.sol";
import "./interfaces/ISandboxLimitOrderRouter.sol";
import "./interfaces/IConveyorExecutor.sol";

/// @title SandboxRouter
/// @author 0xOsiris, 0xKitsune, Conveyor Labs
/// @notice SandboxRouter uses a multiCall architecture to execute limit orders.
contract SandboxLimitOrderRouter is ISandboxLimitOrderRouter {
    using SafeERC20 for IERC20;
    ///@notice ConveyorExecutor & LimitOrderRouter Addresses.
    address immutable LIMIT_ORDER_EXECUTOR;
    address immutable SANDBOX_LIMIT_ORDER_BOOK;

    ///@notice Minimum time between checkins.
    uint256 public constant CHECK_IN_INTERVAL = 1 days;

    ///@notice Modifier to restrict addresses other than the ConveyorExecutor from calling the contract
    modifier onlyLimitOrderExecutor() {
        if (msg.sender != LIMIT_ORDER_EXECUTOR) {
            revert MsgSenderIsNotLimitOrderExecutor();
        }
        _;
    }

    ///@notice Multicall Order Struct for multicall optimistic Order execution.
    ///@param orderIdBundles - Array of orderIds that will be executed.
    ///@param fillAmounts - Array of quantities representing the quantity to be filled.
    ///@param transferAddresses - Array of addresses specifying where to transfer each order quantity at the corresponding index in the array.
    ///@param calls - Array of Call, specifying the address to call and the calldata to execute within the targetAddress context.
    struct SandboxMulticall {
        bytes32[][] orderIdBundles;
        uint128[] fillAmounts;
        address[] transferAddresses;
        Call[] calls;
    }

    ///@param target - Represents the target addresses to be called during execution.
    ///@param callData - Represents the calldata to be executed at the target address.
    struct Call {
        address target;
        bytes callData;
    }

    ///@notice Constructor for the sandbox router contract.
    ///@param _limitOrderExecutor - The ConveyorExecutor contract address.
    ///@param _sandboxLimitOrderBook - The SandboxLimitOrderBook contract address.
    constructor(address _limitOrderExecutor, address _sandboxLimitOrderBook) {
        LIMIT_ORDER_EXECUTOR = _limitOrderExecutor;
        SANDBOX_LIMIT_ORDER_BOOK = _sandboxLimitOrderBook;
    }

    ///@notice Function to execute multiple OrderGroups
    ///@param sandboxMultiCall The calldata to be executed by the contract.
    function executeSandboxMulticall(SandboxMulticall calldata sandboxMultiCall)
        external
    {
        uint256 lastCheckInTime = IConveyorExecutor(LIMIT_ORDER_EXECUTOR)
            .lastCheckIn(msg.sender);

        ///@notice Check if the last checkin time is greater than the checkin interval.
        if (block.timestamp - lastCheckInTime > CHECK_IN_INTERVAL) {
            ///@notice If the last checkin time is greater than the checkin interval, revert.
            revert ExecutorNotCheckedIn();
        }

        ISandboxLimitOrderBook(SANDBOX_LIMIT_ORDER_BOOK)
            .executeOrdersViaSandboxMulticall(sandboxMultiCall);
    }

    ///@notice Callback function that executes a sandbox multicall and is only accessible by the limitOrderExecutor.
    ///@param sandboxMulticall - Struct containing the SandboxMulticall data. See the SandboxMulticall struct for a description of each parameter.
    function sandboxRouterCallback(SandboxMulticall calldata sandboxMulticall)
        external
        onlyLimitOrderExecutor
    {
        ///@notice Iterate through each target in the calls, and optimistically call the calldata.
        for (uint256 i = 0; i < sandboxMulticall.calls.length; ) {
            Call memory sandBoxCall = sandboxMulticall.calls[i];
            ///@notice Call the target address on the specified calldata
            (bool success, ) = sandBoxCall.target.call(sandBoxCall.callData);

            if (!success) {
                revert SandboxCallFailed(i);
            }

            unchecked {
                ++i;
            }
        }
    }

    ///@notice Uniswap V3 callback function called during a swap on a v3 liqudity pool.
    ///@param amount0Delta - The change in token0 reserves from the swap.
    ///@param amount1Delta - The change in token1 reserves from the swap.
    ///@param data - The data packed into the swap.
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external {
        ///@notice Decode all of the swap data.
        (bool _zeroForOne, address tokenIn, address _sender) = abi.decode(
            data,
            (bool, address, address)
        );

        ///@notice Set amountIn to the amountInDelta depending on boolean zeroForOne.
        uint256 amountIn = _zeroForOne
            ? uint256(amount0Delta)
            : uint256(amount1Delta);

        if (!(_sender == address(this))) {
            ///@notice Transfer the amountIn of tokenIn to the liquidity pool from the sender.
            IERC20(tokenIn).safeTransferFrom(_sender, msg.sender, amountIn);
        } else {
            IERC20(tokenIn).safeTransfer(msg.sender, amountIn);
        }
    }
}