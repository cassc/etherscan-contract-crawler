pragma solidity 0.8.6;

import "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";

contract UBeacon is UpgradeableBeacon {
  constructor (address implementation_) UpgradeableBeacon(implementation_) {}
}