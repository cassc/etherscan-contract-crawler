// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.12;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ILiquidityGauge is IERC20 {
    // solhint-disable-next-line
    function claim_rewards(address _addr) external;

    // solhint-disable-next-line
    function claim_rewards(address _addr, address _receiver) external;

    // solhint-disable-next-line
    function claim_rewards_for(address _addr, address _receiver) external;

    // solhint-disable-next-line
    function deposit_reward_token(address _reward_token, uint256 _amount) external;
}