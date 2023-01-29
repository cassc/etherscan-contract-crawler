// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../ERC20Base.sol";
import "../features/BlacklistFeature.sol";
import "../features/ERC20BurnFeature.sol";
import "../features/ERC20MintFeature.sol";

contract BlacklistBurnMintTemplate is
    ERC20Base,
    BlacklistFeature,
    ERC20BurnFeature,
    ERC20MintFeature
{
    function initialize(
        string calldata name_,
        string calldata symbol_,
        uint8 decimals_,
        uint256 amount_
    ) external virtual initializer {
        __ERC20Base_init(name_, symbol_, decimals_, amount_);
        __ERC20MintFeature_init_unchained();
        __ERC20Burnable_init_unchained();
        __BlacklistFeature_init_unchained();
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

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20Upgradeable) {
        BlacklistFeature._beforeTokenTransfer_hook(from, to, amount);
        super._beforeTokenTransfer(from, to, amount);
    }
}