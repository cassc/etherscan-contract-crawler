// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract D3MMLiquidationRouter {
    using SafeERC20 for IERC20;

    address public immutable _DODO_APPROVE_;

    constructor(address dodoApprove) {
        _DODO_APPROVE_ = dodoApprove;
    }

    struct LiquidationOrder {
        address fromToken;
        address toToken;
        uint256 fromAmount;
    }

    /// @notice D3MM call this function to do liquidation swap
    /// @param order The liquidation order
    /// @param router The router contract address
    /// @param routeData The data will be parsed to router call
    function D3Callee(LiquidationOrder calldata order, address router, bytes calldata routeData) external {
        IERC20(order.fromToken).forceApprove(_DODO_APPROVE_, type(uint256).max);
        (bool success, bytes memory data) = router.call(routeData);
        if (!success) {
            assembly {
                revert(add(data, 32), mload(data))
            }
        }
        IERC20(order.toToken).safeTransfer(msg.sender, IERC20(order.toToken).balanceOf(address(this)));
    }
}