// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/proxy/Proxy.sol";
import "@openzeppelin/contracts/utils/Address.sol";

pragma solidity ^0.8.13;

contract EvoProxy is Proxy {
    bytes32 internal constant _ADMIN_SLOT =
        0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;
    bytes32 internal constant _IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    event Upgraded(address indexed implementation);
    event AdminChanged(address indexed admin);

    modifier ifAdmin() {
        if (msg.sender == _admin()) {
            _;
        } else {
            _fallback();
        }
    }

    constructor(address admin_) {
        assembly {
            sstore(_ADMIN_SLOT, admin_)
        }
        emit AdminChanged(admin_);
    }

    function _admin() internal view returns (address admin_) {
        assembly {
            admin_ := sload(_ADMIN_SLOT)
        }
    }

    function _implementation()
        internal
        view
        virtual
        override
        returns (address implementation_)
    {
        assembly {
            implementation_ := sload(_IMPLEMENTATION_SLOT)
        }
    }

    function _beforeFallback() internal virtual override {
        require(
            msg.sender != _admin(),
            "Admin cannot fallback to proxy target"
        );
        super._beforeFallback();
    }

    function admin() external ifAdmin returns (address admin_) {
        admin_ = _admin();
    }

    function implementation() external ifAdmin returns (address implementation_) {
        implementation_ = _implementation();
    }

    function upgradeTo(address newImplementation) public ifAdmin {
        require(
            Address.isContract(newImplementation),
            "Implementation must be a contract"
        );
        assembly {
            sstore(_IMPLEMENTATION_SLOT, newImplementation)
        }
        emit Upgraded(newImplementation);
    }

    function upgradeToAndCall(address newImplementation, bytes memory data)
        external
        ifAdmin
    {
        upgradeTo(newImplementation);
        Address.functionDelegateCall(newImplementation, data);
    }
}