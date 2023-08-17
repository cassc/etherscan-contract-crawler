// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "closedsea/src/OperatorFilterer.sol";

error RegistryNotEnabled();

abstract contract SanFranTokyoGenesisPassOperatorFilterer is
  Ownable,
  OperatorFilterer
{
  // Operator filtering switch toggle
  bool public operatorFilteringEnabled = true;

  /**
   *
   * @dev setter for operatorFilteringEnabled variable
   */
  function setOperatorFilteringEnabled(bool value) public onlyOwner {
    operatorFilteringEnabled = value;
  }

  /**
   *
   * @dev registers the current contract to OpenSea's operator filter
   * @param defaultFiltererSubscription address of the filterer list to copy
   * @param subscribe boolean to subscribe or unsubscribe from the FILTER_REGISTRY
   */
  function registerForOperatorFiltering(
    address defaultFiltererSubscription,
    bool subscribe
  ) public onlyOwner {
    if (!operatorFilteringEnabled) {
      revert RegistryNotEnabled();
    }

    _registerForOperatorFiltering(defaultFiltererSubscription, subscribe);
  }

  /**
   * @dev override OperatorFilterer.sol to use operatorFilteringEnabled variable
   * as a switch toggle for operator filtering
   */
  function _operatorFilteringEnabled() internal view override returns (bool) {
    return operatorFilteringEnabled;
  }
}