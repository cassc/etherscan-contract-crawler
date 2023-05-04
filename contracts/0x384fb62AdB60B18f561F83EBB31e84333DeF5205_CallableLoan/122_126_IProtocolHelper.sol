// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

import {IGoldfinchConfig} from "../../interfaces/IGoldfinchConfig.sol";
import {IGoldfinchFactory} from "../../interfaces/IGoldfinchFactory.sol";
import {IERC20} from "../../interfaces/IERC20.sol";
import {IStakingRewards} from "../../interfaces/IStakingRewards.sol";

interface IProtocolHelper {
  function gfConfig() external returns (IGoldfinchConfig);

  function fidu() external returns (IERC20);

  function gfi() external returns (IERC20);

  function gfFactory() external returns (IGoldfinchFactory);

  function stakingRewards() external returns (IStakingRewards);

  function usdc() external returns (IERC20);
}