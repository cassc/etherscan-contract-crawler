// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";

/**
 */
abstract contract IdGenerator is Initializable {
  using CountersUpgradeable for CountersUpgradeable.Counter;

  CountersUpgradeable.Counter private _sellingAgreementId;

  function __IdGenerator_init() internal onlyInitializing {
    _sellingAgreementId.increment();
  }

  function getSellingAgreementId() internal view returns (uint256) {
    return _sellingAgreementId.current();
  }

  function incrementSellingAgreementId() internal {
    return _sellingAgreementId.increment();
  }

  /**
   * @notice This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   */

  uint256[1_000] private __gap;
}