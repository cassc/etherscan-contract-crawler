// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./Ownable.sol";

abstract contract OwnableUpgrade is Ownable, Initializable {
  function __OwnableUpgrade_init() internal onlyInitializing {
    __Ownable_init();
  }
}