// SPDX-License-Identifier: MIT
// contracts/modules/TokenBlack.sol

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract TokenBlack is AccessControlEnumerableUpgradeable, ERC20PausableUpgradeable {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    EnumerableSetUpgradeable.AddressSet private _blackList;

    function setMultipleBlackAddress(address[] memory accounts, bool enable) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "TokenBlack: Must have admin role to set excluded fee address");

        for (uint256 i = 0; i < accounts.length; i++) {
            setBlackAddress(accounts[i], enable);
        }
    }

    function setBlackAddress(address account, bool enable) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "TokenBlack: Must have admin role to set black address");

        if (enable) {
            require(!_blackList.contains(account), "TokenBlack: Address is exist");
            _blackList.add(account);
        } else {
            require(_blackList.contains(account), "TokenBlack: Address not exist");
            _blackList.remove(account);
        }
    }

    function isBlackAddress(address account) public view returns (bool) {
        return _blackList.contains(account);
    }

    function getBlackAddressTotal() public view returns (uint256) {
        return _blackList.length();
    }

    function getBlackAddressIndex(uint256 index) public view returns (address) {
        require(index < _blackList.length(), "TokenBlack: Excluded from fee index out of bounds");

        return _blackList.at(index);
    }

    function pause() public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "TokenBlack: Must have admin role to pause");

        _pause();
    }

    function unpause() public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "TokenBlack: Must have admin role to unpause");

        _unpause();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        require(!isBlackAddress(from), "TokenBlack: Blacklisted send address");
        require(!isBlackAddress(to), "TokenBlack: Blacklisted receive address");
    }

    uint256[50] private __gap;
}