// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../ERC20Base.sol";
import "../features/SnapshotFeature.sol";
import "../features/BlacklistFeature.sol";
import "../features/ERC20MintFeature.sol";
import "../features/ERC20BurnFeature.sol";

contract BlacklistBurnMintSnapshotTemplate is
    SnapshotFeature,
    BlacklistFeature,
    ERC20MintFeature,
    ERC20BurnFeature
{
    function initialize(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 amount_
    ) public initializer {
        __ERC20Base_init(name_, symbol_, decimals_, amount_);
        __BlacklistFeature_init_unchained();
        __ERC20MintFeature_init_unchained();
    }

    function grantRole(bytes32 role, address account)
        public
        override(AccessControlUpgradeable)
    {
        BlacklistFeature.grantRole_hook(role, account);
        super.grantRole(role, account);
    }

    function renounceRole(bytes32 role, address account)
        public
        override(AccessControlUpgradeable)
    {
        BlacklistFeature.renounceRole_hook(role, account);
        super.renounceRole(role, account);
    }

    function _beforeTokenTransfer_hook(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(SnapshotFeature, BlacklistFeature) {
        SnapshotFeature._beforeTokenTransfer_hook(from, to, amount);
        BlacklistFeature._beforeTokenTransfer_hook(from, to, amount);
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