//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './IFraxFarmERC20.sol';

interface IStakingProxyConvex {
    function stakingAddress() external view returns (IFraxFarmERC20);

    function stakeLockedCurveLp(uint256 _liquidity, uint256 _secs)
        external
        returns (bytes32 kek_id);

    function lockAdditionalCurveLp(bytes32 _kek_id, uint256 _addl_liq) external;

    function lockLonger(bytes32 _kek_id, uint256 new_ending_ts) external;

    function withdrawLockedAndUnwrap(bytes32 _kek_id) external;

    function earned()
        external
        view
        returns (address[] memory token_addresses, uint256[] memory total_earned);

    function getReward(bool _claim) external;
}