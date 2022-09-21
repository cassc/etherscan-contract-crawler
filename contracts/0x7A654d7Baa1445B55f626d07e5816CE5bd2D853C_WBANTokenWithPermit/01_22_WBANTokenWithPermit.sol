// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

import "./WBANToken.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-ERC20PermitUpgradeable.sol";

/**
 * wBAN token with mints and burns controlled by the bridge.
 *
 * @dev this version introduces permit feature
 *
 * @author Wrap That Potassium <[email protected]>
 */
contract WBANTokenWithPermit is WBANToken, ERC20PermitUpgradeable {
    function initializeWithPermit() public reinitializer(2) {
        __ERC20Permit_init(super.name());
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20Upgradeable, ERC20PausableUpgradeable) {
        super._beforeTokenTransfer(from, to, amount);
    }
}