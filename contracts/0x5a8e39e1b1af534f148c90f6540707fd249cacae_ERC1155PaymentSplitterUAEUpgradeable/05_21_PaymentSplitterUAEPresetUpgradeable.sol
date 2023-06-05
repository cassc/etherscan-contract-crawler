// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./PaymentSplitterUpgradeable.sol";

contract PaymentSplitterUAEPresetUpgradeable is Initializable, ContextUpgradeable, ReentrancyGuardUpgradeable, PaymentSplitterUpgradeable {
    function __PaymentSplitterUAEPreset_init(
        address[] memory payees_,
        uint256[] memory shares_
    ) internal initializer {
        __Context_init_unchained();
        __ReentrancyGuard_init_unchained();
        __PaymentSplitter_init_unchained(payees_, shares_);
        __PaymentSplitterUAEPreset_init_unchained();
    }

    function __PaymentSplitterUAEPreset_init_unchained() internal initializer {
    }

    function release(address payable account_) public virtual override nonReentrant {
        require(_msgSender() == account_, "PaymentSplitterUAE: msgSender mismatch");
        return super.release(account_);
    }

    function release(IERC20Upgradeable token_, address account_) public virtual override nonReentrant {
        require(_msgSender() == account_, "PaymentSplitterUAE: msgSender mismatch");
        return super.release(token_, account_);
    }

    uint256[50] private __gap;
}