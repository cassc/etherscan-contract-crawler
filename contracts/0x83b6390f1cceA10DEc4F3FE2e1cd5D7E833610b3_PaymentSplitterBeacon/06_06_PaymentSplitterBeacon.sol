// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";

contract PaymentSplitterBeacon is UpgradeableBeacon {
    constructor(address impl) UpgradeableBeacon(impl) {}
}