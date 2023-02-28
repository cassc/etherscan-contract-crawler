// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./Include.sol";


contract Bank is Governable {
    using SafeERC20 for IERC20;

    address public reward;

    function __Bank_init(address governor, address reward_) public initializer {
        __Governable_init_unchained(governor);
        __Bank_init_unchained(reward_);
    }
    
    function __Bank_init_unchained(address reward_) internal governance initializer {
        reward = reward_;
    }
    
    function approvePool(address pool, uint amount) public governance {
        IERC20(reward).approve(pool, amount);
    }
    
    function approveToken(address token, address pool, uint amount) public governance {
        IERC20(token).approve(pool, amount);
    }

    // Reserved storage space to allow for layout changes in the future.
    uint256[50] private ______gap;
}