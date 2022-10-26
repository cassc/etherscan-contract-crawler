// SPDX-License-Identifier: BSD-3-Clause

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./IHandler.sol";

abstract contract HandlerAwareUpgradeable is Initializable {
    IHandler internal _handler;
    modifier onlyHandler() {
        require(msg.sender == address(_handler));
        _;
    }

    function __HandlerAware_init(IHandler handler) internal onlyInitializing {
        __HandlerAware_init_unchained(handler);
    }

    function __HandlerAware_init_unchained(IHandler handler) internal onlyInitializing {
        _handler = handler;
    }
}