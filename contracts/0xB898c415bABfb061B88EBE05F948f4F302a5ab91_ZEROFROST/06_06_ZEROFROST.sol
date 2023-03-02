// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IZEROFROST } from "../interfaces/IZEROFROST.sol";
import "@openzeppelin/contracts-upgradeable-new/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable-new/proxy/utils/Initializable.sol";

// dummy contract to just return epoch length for now
contract ZEROFROST is Initializable, OwnableUpgradeable, IZEROFROST {
  function initialize() public initializer {
    __Ownable_init_unchained();
  }

  function epoch() public view returns (uint256) {
    return 0;
  }

  function nextEpoch() public view returns (uint256) {
    return 0;
  }

  function epochLength() public view returns (uint256) {
    return 3600 * 24 * 180;
  }
}