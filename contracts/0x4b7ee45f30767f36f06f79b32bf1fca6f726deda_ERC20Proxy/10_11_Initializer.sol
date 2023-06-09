// SPDX-License-Identifier: UNLICENSED
// Copyright (c) 2020 Gemini Trust Company LLC. All Rights Reserved
pragma solidity ^0.7.0;

import "./ERC20Proxy.sol";
import "./ERC20Impl.sol";
import "./ERC20Store.sol";

contract Initializer {

  function initialize(
      ERC20Store _store,
      ERC20Proxy _proxy,
      ERC20Impl _impl,
      address _implChangeCustodian,
      address _printCustodian) external {

    // set impl as active implementation for store and proxy
    _store.confirmImplChange(_store.requestImplChange(address(_impl)));
    _proxy.confirmImplChange(_proxy.requestImplChange(address(_impl)));

    // pass custodianship of store and proxy to impl change custodian
    _store.confirmCustodianChange(_store.requestCustodianChange(_implChangeCustodian));
    _proxy.confirmCustodianChange(_proxy.requestCustodianChange(_implChangeCustodian));

    // pass custodianship of impl to print custodian
    _impl.confirmCustodianChange(_impl.requestCustodianChange(_printCustodian));
  }

}