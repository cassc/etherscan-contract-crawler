//SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../admin-manager/AdminManagerUpgradable.sol";

abstract contract AdminMintUpgradable is Initializable, AdminManagerUpgradable {
    function __AdminMint_init() internal onlyInitializing {
        __AdminManager_init_unchained();
        __AdminMint_init_unchained();
    }

    function __AdminMint_init_unchained() internal onlyInitializing {}

    function adminMint(
        address[] calldata accounts_,
        uint256[] calldata amounts_
    ) external onlyAdmin {
        uint256 accountsLength = accounts_.length;
        require(accountsLength == amounts_.length, "Admin mint: bad request");
        for (uint256 i; i < accountsLength; i++) {
            _adminMint(accounts_[i], amounts_[i]);
        }
    }

    function _adminMint(address account_, uint256 amount_) internal virtual;

    uint256[50] private __gap;
}