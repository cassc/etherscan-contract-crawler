// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StorageSlotUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./ERC1967Proxy.sol";



contract ProxyImplementation is Initializable
{
    bytes32 private constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
    bytes32 private constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    modifier onlyAdmin() 
    {
        require(admin() == msg.sender, "Implementation: caller is not admin");
        _;
    }

    function getImplementation() public view returns(address)
    {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    function setImplementation(address implementation) public virtual onlyAdmin
    {
        require(AddressUpgradeable.isContract(implementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = implementation;
    }

    function admin() public view returns(address)
    {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    function owner() public view returns(address)
    {
        return admin();
    }

    function setAdmin(address newAdmin) public virtual onlyAdmin
    {
        require(newAdmin != address(0), "invalid newAdmin address");
        _setAdmin(newAdmin);
    }

    function renounceAdminPowers() public virtual onlyAdmin
    {
        _setAdmin(address(0));
    }

    function _setAdmin(address newAdmin) private
    {
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }
}