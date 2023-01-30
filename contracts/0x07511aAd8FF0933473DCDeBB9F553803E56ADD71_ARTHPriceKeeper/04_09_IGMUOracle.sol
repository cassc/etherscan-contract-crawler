//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import { IPriceFeed } from "./IPriceFeed.sol";
import { IEpoch } from "./IEpoch.sol";

interface IGMUOracle is IPriceFeed, IEpoch {
  function updatePrice() external;
}