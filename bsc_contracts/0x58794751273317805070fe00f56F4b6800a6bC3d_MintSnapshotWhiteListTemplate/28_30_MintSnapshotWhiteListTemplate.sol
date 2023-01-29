// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../ERC20Base.sol";
import "../features/SnapshotFeature.sol";
import "../features/PausableWithWhitelistFeature.sol";
import "../features/ERC20MintFeature.sol";

contract MintSnapshotWhiteListTemplate is
    SnapshotFeature,
    PausableWithWhitelistFeature,
    ERC20MintFeature
{
    function initialize(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 amount_
    ) public initializer {
        __ERC20Base_init(name_, symbol_, decimals_, amount_);
        __ERC20MintFeature_init_unchained();
    }

    function _beforeTokenTransfer_hook(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(SnapshotFeature, PausableWithWhitelistFeature) {
        SnapshotFeature._beforeTokenTransfer_hook(from, to, amount);
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
    ) internal virtual override(ERC20SnapshotRewrited, ERC20Upgradeable) {
        _beforeTokenTransfer_hook(from, to, amount);
        super._beforeTokenTransfer(from, to, amount);
    }
}