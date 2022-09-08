// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import "@openzeppelin-contracts/contracts/proxy/transparent/ProxyAdmin.sol";
import "@openzeppelin-upgradeable/contracts/access/OwnableUpgradeable.sol";

contract PitchProxyAdmin is ProxyAdmin {
    function initializeImplementation(address _impl, bytes memory _data) external onlyOwner {
        (bool success, bytes memory data) = _impl.call(_data);

        require(success, "!ImplInit");

        emit ContractInitialized(_impl, success, data);
    }

    function changeImplementationOwner(address _impl, address _newOwner) external onlyOwner {
        OwnableUpgradeable impl = OwnableUpgradeable(_impl);
        impl.transferOwnership(_newOwner);
    }

    event ContractInitialized(address indexed impl, bool success, bytes data);
}