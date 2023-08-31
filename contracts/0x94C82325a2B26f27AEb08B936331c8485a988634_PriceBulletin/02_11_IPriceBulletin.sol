// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import {IAggregatorV3} from "./chainlink/IAggregatorV3.sol";
import {IXReceiver} from "./connext/IConnext.sol";

interface IPriceBulletin is IAggregatorV3, IXReceiver {
  function setAuthorizedPublisher(address publisher, bool set) external;
}