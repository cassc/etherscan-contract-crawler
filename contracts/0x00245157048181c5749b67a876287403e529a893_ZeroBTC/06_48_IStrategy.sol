// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import { GlobalState } from "../erc4626/storage/ZeroBTCStorage.sol";

interface IStrategy {
  function manage(GlobalState old) external returns (GlobalState state);
}