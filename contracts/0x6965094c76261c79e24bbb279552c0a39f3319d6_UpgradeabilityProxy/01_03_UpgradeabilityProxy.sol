// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
contract UpgradeabilityProxy {

    using SafeMath for uint;

    bytes32 private constant proxyOwnerPosition = keccak256("proxy.owner");
    bytes32 private constant newProxyOwnerPosition = keccak256("proxy.newOwner");
    bytes32 private constant implementationPosition = keccak256("proxy.implementation");
    bytes32 private constant newImplementationPosition = keccak256("proxy.newImplementation");
    bytes32 private constant timelockPosition = keccak256("proxy.timelock");
    uint public constant timelockPeriod = 21600; // 6 hours

    constructor (address _proxyOwner, address _implementation, bytes memory initializationData, bool forceCall) {
        _setProxyOwner(_proxyOwner);
        _setImplementation(_implementation);
        if (initializationData.length > 0 || forceCall) {
            Address.functionDelegateCall(implementation(), initializationData);
        }
    }

    function proxyOwner() public view returns (address _proxyOwner) {
        bytes32 position = proxyOwnerPosition;
        assembly {
            _proxyOwner := sload(position)
        }
    }

    function newProxyOwner() public view returns (address _newProxyOwner) {
        bytes32 position = newProxyOwnerPosition;
        assembly {
            _newProxyOwner := sload(position)
        }
    }

    function _setProxyOwner(address _newProxyOwner) private {
        bytes32 position = proxyOwnerPosition;
        assembly {
            sstore(position, _newProxyOwner)
        }
    }

    function setNewProxyOwner(address _newProxyOwner) public {
        require(msg.sender == proxyOwner(), "UpgradeabilityProxy: only current proxy owner can set new proxy owner.");
        bytes32 position = newProxyOwnerPosition; 
        assembly {
            sstore(position, _newProxyOwner)
        }
    }

    function transferProxyOwnership() public {
        address _newProxyOwner = newProxyOwner();
        require(msg.sender == _newProxyOwner, "UpgradeabilityProxy: only new owner can transfer ownership.");
        _setProxyOwner(_newProxyOwner);
    }

    function implementation() public view returns (address _implementation) {
        bytes32 position = implementationPosition;
        assembly {
            _implementation := sload(position)
        }
    }

    function newImplementation() public view returns (address _newImplementation) {
        bytes32 position = newImplementationPosition;
        assembly {
            _newImplementation := sload(position)
        }
    } 

    function timelock() public view returns (uint _timelock) {
        bytes32 position = timelockPosition;
        assembly {
            _timelock := sload(position)
        }
    }

    function _setTimelock(uint newTimelock) private {
        bytes32 position = timelockPosition;
        assembly {
            sstore(position, newTimelock)
        }
    }

    function _setImplementation(address _newImplementation) private {
        bytes32 position = implementationPosition;
        assembly {
            sstore(position, _newImplementation)
        }
    }


    function setNewImplementation(address _newImplementation) public {
        require(msg.sender == proxyOwner(), "UpgradeabilityProxy: only current proxy owner can set new implementation.");
        bytes32 position = newImplementationPosition; 
        assembly {
            sstore(position, _newImplementation)
        }
        uint newTimelock = block.timestamp.add(timelockPeriod);
        _setTimelock(newTimelock);
    }

    function transferImplementation() public {
        require(msg.sender == proxyOwner(), "UpgradeabilityProxy: only proxy owner can transfer implementation.");
        require(block.timestamp >= timelock(), "UpgradeabilityProxy: cannot transfer implementation yet.");
        _setImplementation(newImplementation());
    }

    function _delegate(address _implementation) internal virtual {
        assembly {
            calldatacopy(0, 0, calldatasize())


            let result := delegatecall(gas(), _implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }


    fallback () external payable virtual {
        _delegate(implementation());
    }


    receive () external payable virtual {
        _delegate(implementation());
    }
}