// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.16;

import {CometStructs} from "./IComet.sol";

// @dev See https://github.com/compound-developers/compound-3-developer-faq/blob/61eccdeb3155a53e180bb5689d2afb4c1f36908f/contracts/MyContract.sol#LL90C1-L93C2
interface IRewards {
  function getRewardOwed(address comet, address account) external returns (CometStructs.RewardOwed memory);
  function claim(address comet, address src, bool shouldAccrue) external;
}