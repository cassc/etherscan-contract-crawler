// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../ERC20Base.sol";
import "../features/PausableWithWhitelistFeature.sol";

contract WhiteListTemplate is ERC20Base, PausableWithWhitelistFeature {
    function initialize(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 amount_
    ) public virtual initializer {
        __ERC20Base_init(name_, symbol_, decimals_, amount_);
        __PausableWithWhitelistFeature_init_unchained();
    }

    function _beforeTokenTransfer_hook(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(PausableWithWhitelistFeature) {
        PausableWithWhitelistFeature._beforeTokenTransfer_hook(
            from,
            to,
            amount
        );
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20Upgradeable) {
        _beforeTokenTransfer_hook(from, to, amount);
        super._beforeTokenTransfer(from, to, amount);
    }
}