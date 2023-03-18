// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract Adapter {
    address internal constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    function _approveIfNeeded(IERC20 token_, address spender_, uint256 amount_) internal {
        if (address(token_) == ETH) {
            return;
        }

        if (token_.allowance(address(this), spender_) < amount_) {
            token_.approve(spender_, type(uint256).max);
        }
    }
}