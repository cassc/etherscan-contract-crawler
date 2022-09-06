// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import { ProxyOwnable } from  "./ProxyOwnable.sol";
import { Ownable } from "./Ownable.sol";


contract Proxy is ProxyOwnable, Ownable {
    bytes32 private constant implementationPosition = keccak256("implementation.contract:2022");
    
    event Upgraded(address indexed implementation);

    constructor(address _impl) ProxyOwnable() Ownable() {
        _setImplementation(_impl);
    }

    function implementation() public view returns (address impl) {
        bytes32 position = implementationPosition;
        assembly {
            impl := sload(position)
        }
    }

    function upgradeTo(address _newImplementation) public onlyProxyOwner {
        address currentImplementation = implementation();
        require(currentImplementation != _newImplementation, "Same implementation");
        _setImplementation(_newImplementation);
        emit Upgraded(_newImplementation);
    }

    function _setImplementation(address _newImplementation) internal {
        bytes32 position = implementationPosition;
        assembly {
            sstore(position, _newImplementation)
        }
    }

    function _delegatecall() internal {
        address _impl = implementation();
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), _impl, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())

            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    fallback() external {
        _delegatecall();
    }

    receive() external payable {
        _delegatecall();
    }
}