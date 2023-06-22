// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import "./CErc20PluginDelegate.sol";

contract CErc20PluginRewardsDelegate is CErc20PluginDelegate {
  /// @notice A reward token claim function
  /// to be overridden for use cases where rewardToken needs to be pulled in
  function claim() external {}

  /// @notice token approval function
  function approve(address _token, address _spender) external {
    require(hasAdminRights(), "!admin");
    require(_token != underlying && _token != address(plugin), "!");

    EIP20Interface(_token).approve(_spender, type(uint256).max);
  }

  function contractType() external pure override returns (string memory) {
    return "CErc20PluginRewardsDelegate";
  }
}