// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;
import { ContextUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import { EnumerableSetUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import { IBusinessAddresses } from "./interfaces/IBusinessAddresses.sol";

abstract contract BusinessAddresses is IBusinessAddresses, ContextUpgradeable {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    EnumerableSetUpgradeable.AddressSet private _businessAddressSet;

    modifier onlyBusiness() {
        address sender = _msgSender();
        if (!_businessAddressSet.contains(sender)) revert BusinessAddresses__NotAuthorized();
        _;
    }

    function _inBusinessList(address address_) internal view returns (bool) {
        return _businessAddressSet.contains(address_);
    }

    function _acceptBusinessAddresses(address[] memory businessAddresses_) internal {
        uint256 length = businessAddresses_.length;
        for (uint256 i = 0; i < length; ) {
            address businessAddress = businessAddresses_[i];
            if (_businessAddressSet.contains(businessAddresses_[i])) revert BusinessAddresses__Existed();
            _businessAddressSet.add(businessAddress);
            unchecked {
                ++i;
            }
        }
        emit BusinessNew(businessAddresses_);
    }

    function _cancelBusinessAddresses(address[] memory businessAddresses_) internal {
        uint256 length = businessAddresses_.length;
        for (uint256 i = 0; i < length; ) {
            address businessAddress = businessAddresses_[i];
            if (!_businessAddressSet.contains(businessAddresses_[i])) revert BusinessAddresses__NotExist();
            _businessAddressSet.remove(businessAddress);
            unchecked {
                ++i;
            }
        }
        emit BusinessCancel(businessAddresses_);
    }

    function viewBusinessListsCount() external view returns (uint256) {
        return _businessAddressSet.length();
    }

    function viewBusinessLists(uint256 cursor, uint256 size) external view returns (address[] memory businessAddresses, uint256) {
        uint256 length = size;
        if (length > _businessAddressSet.length() - cursor) length = _businessAddressSet.length() - cursor;
        businessAddresses = new address[](length);
        for (uint256 i = 0; i < length; ) {
            businessAddresses[i] = _businessAddressSet.at(cursor + i);
            unchecked {
                ++i;
            }
        }
        return (businessAddresses, cursor + length);
    }

    uint256[49] private __gap;
}