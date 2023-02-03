// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import {BaseUpgradeablePausable} from "./BaseUpgradeablePausable.sol";
import {ConfigHelper} from "./ConfigHelper.sol";
import {GoldfinchConfig} from "./GoldfinchConfig.sol";
import {LeverageRatioStrategy} from "./LeverageRatioStrategy.sol";
import {ISeniorPoolStrategy} from "../../interfaces/ISeniorPoolStrategy.sol";
import {ISeniorPool} from "../../interfaces/ISeniorPool.sol";
import {ITranchedPool} from "../../interfaces/ITranchedPool.sol";

contract FixedLeverageRatioStrategy is LeverageRatioStrategy {
  GoldfinchConfig public config;
  using ConfigHelper for GoldfinchConfig;

  event GoldfinchConfigUpdated(address indexed who, address configAddress);

  function initialize(address owner, GoldfinchConfig _config) public initializer {
    require(
      owner != address(0) && address(_config) != address(0),
      "Owner and config addresses cannot be empty"
    );
    __BaseUpgradeablePausable__init(owner);
    config = _config;
  }

  function getLeverageRatio(ITranchedPool) public view override returns (uint256) {
    return config.getLeverageRatio();
  }
}