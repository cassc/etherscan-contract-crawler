// SPDX-License-Identifier: GPL-2.0
pragma solidity 0.8.10;


import {CowSwapSeller} from "CowSwapSeller.sol";

import {IERC20} from "IERC20.sol";
import {SafeERC20} from "SafeERC20.sol";

contract CowSwapDemoSeller is CowSwapSeller {
    using SafeERC20 for IERC20;

    constructor(address _pricer) CowSwapSeller(_pricer) {}

    function initiateCowswapOrder(Data calldata orderData, bytes memory orderUid) external {
        _doCowswapOrder(orderData, orderUid);
    }


    function cancelCowswapOrder(bytes memory orderUid) external {
        _cancelCowswapOrder(orderUid);
    }

    function sendTokenBack(IERC20 token) external nonReentrant {
        require(msg.sender == manager);

        token.safeApprove(RELAYER, 0); // Remove approval in case we had pending order
        token.safeTransfer(manager, token.balanceOf(address(this)));
    }
}