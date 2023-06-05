// SPDX-License-Identifier: CC0
pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./IMaliciousRegister.sol";
import "./Ownable.sol";

abstract contract MaliciousRegister is
    IMaliciousRegister,
    Ownable,
    Pausable
{
    mapping(address => bool) private _isMaliciousAccount;

    modifier noMalicious() {
        require(
            !isMaliciousAccount(_msgSender()),
            "MaliciousRegister you can't do this action, your address has been marked as malicious."
        );

        _;
    }

    modifier noMaliciousAddress(address addressToCheck) {
        require(
            !isMaliciousAccount(addressToCheck),
            "MaliciousRegister you can't do this action, the address you used has been marked as malicious."
        );

        _;
    }

    function isMaliciousAccount(
        address accountToCheck
    ) public view override returns (bool) {
        return _isMaliciousAccount[accountToCheck];
    }

    function addMaliciousAccounts(
        address[] memory accountsToAdd
    ) external override onlyOwner whenNotPaused returns (bool added) {
        for (uint i = 0; i < accountsToAdd.length; i++) {
            _isMaliciousAccount[accountsToAdd[i]] = true;
        }

        return true;
    }

    function removeMaliciousAccounts(
        address[] memory accountsToRemove
    ) external override onlyOwner whenNotPaused returns (bool removed) {
        for (uint i = 0; i < accountsToRemove.length; i++) {
            _isMaliciousAccount[accountsToRemove[i]] = false;
        }

        return true;
    }
}