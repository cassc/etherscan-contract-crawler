// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./AdminWithMinterBurnerControl.sol";
import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';
import 'contract-allow-list/contracts/proxy/interface/IContractAllowListProxy.sol';

contract CNCCCal is AdminWithMinterBurnerControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet private localAllowedAddresses;
    struct CalInfo {
        IContractAllowListProxy cal;
        uint80 calLevel;
        bool enableRestrict;
        bool isSBT; // false
    }
    CalInfo private calInfo;

    function getCalInfo() external view returns (CalInfo memory) {
        return calInfo;
    }

    function setCAL(address value) public onlyAdmin {
        calInfo.cal = IContractAllowListProxy(value);
    }

    function setCALLevel(uint80 value) public onlyAdmin {
        calInfo.calLevel = value;
    }

    function addLocalContractAllowList(address transferer) external onlyAdmin {
        localAllowedAddresses.add(transferer);
    }

    function removeLocalContractAllowList(address transferer) external onlyAdmin {
        localAllowedAddresses.remove(transferer);
    }

    function getLocalContractAllowList() external view returns (address[] memory) {
        return localAllowedAddresses.values();
    }

    function _isAllowed(address transferer) internal view virtual returns (bool) {
        if (!calInfo.enableRestrict) return true;

        return localAllowedAddresses.contains(transferer) || calInfo.cal.isAllowed(transferer, calInfo.calLevel);
    }

    function setEnableRestrict(bool value) public onlyAdmin {
        calInfo.enableRestrict = value;
    }

    function setIsSBT(bool _isSBT) external onlyAdmin {
        calInfo.isSBT = _isSBT;
    }

    function _setApprovalForAllCheck(address operator, bool approved) internal view {
        if (calInfo.isSBT) {
            require(false, "SBT: Can not approve");
        }
        require(_isAllowed(operator) || !approved, 'RestrictApprove: Can not approve locked token');
    }

    function _beforeTokenTransferCheck(address from, address to) internal view {
        if (calInfo.isSBT) {
            require(from == address(0) || to == address(0), 'SBT: Can not transfer');
        }
    }
}