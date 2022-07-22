// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

contract ProxyOwnable {
    bytes32 private constant proxyOwnerPosition = keccak256("proxy.owner:2022");

    event ProxyOwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    modifier onlyProxyOwner() {
        require(msg.sender == proxyOwner(), "Proxy: Caller not proxy owner");
        _;
    }

    constructor() {
        _setUpgradeabilityOwner(msg.sender);
    }

    function proxyOwner() public view returns (address owner) {
        bytes32 position = proxyOwnerPosition;
        assembly {
            owner := sload(position)
        }
    }

    function transferProxyOwnership(address _newOwner) public onlyProxyOwner {
        require(_newOwner != proxyOwner(), "Proxy: new owner is the current owner");
        emit ProxyOwnershipTransferred(proxyOwner(), _newOwner);
        _setUpgradeabilityOwner(_newOwner);
    }

    function _setUpgradeabilityOwner(address _newProxyOwner) internal {
        bytes32 position = proxyOwnerPosition;
        assembly {
            sstore(position, _newProxyOwner)
        }
    }
}