// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import { ITokenAccessControl } from "./interface/ITokenAccessControl.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract AddressAccessControl is Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet private addressSet;

    function addAddress(address addr)
        external
        virtual
        onlyOwner
        returns (bool)
    {
        return _addAddress(addr);
    }

    function addAddresses(address[] memory addresses)
        external
        virtual
        onlyOwner
    {
        _addAddresses(addresses);
    }

    function removeAddress(address addr)
        external
        virtual
        onlyOwner
        returns (bool)
    {
        return addressSet.remove(addr);
    }

    function contains(address addr) external view virtual returns (bool) {
        return addressSet.contains(addr);
    }

    function supportedAddresses()
        external
        view
        virtual
        returns (address[] memory)
    {
        return addressSet.values();
    }

    /**
     * @dev 支持所有 tokens
     *
     */
    function containsAll(address[] memory addresses)
        external
        view
        virtual
        returns (bool)
    {
        for (uint256 index = 0; index < addresses.length; index++) {
            bool result = this.contains(addresses[index]);
            if (!result) return result;
        }
        return true;
    }

    function _checkAllAddresses(address[] memory addresses)
        internal
        view
        virtual
    {
        require(this.containsAll(addresses), "An unsupported token exists!");
    }

    function _checkAddress(address addr) internal view virtual {
        require(this.contains(addr), "An unsupported token exists!");
    }

    function _addAddress(address addr) internal returns (bool) {
        require(addr != address(0), "invalid address.");
        return addressSet.add(addr);
    }

    function _addAddresses(address[] memory addresses) internal {
        for (uint256 index = 0; index < addresses.length; index++) {
            _addAddress(addresses[index]);
        }
    }
}