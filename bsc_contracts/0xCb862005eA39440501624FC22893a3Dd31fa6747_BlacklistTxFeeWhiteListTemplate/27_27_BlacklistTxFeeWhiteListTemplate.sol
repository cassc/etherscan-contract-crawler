// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../ERC20Base.sol";
import "../features/BlacklistFeature.sol";
import "../features/PausableWithWhitelistFeature.sol";
import "../features/TxFeeFeatureV3.sol";

contract BlacklistTxFeeWhiteListTemplate is
    ERC20Base,
    BlacklistFeature,
    PausableWithWhitelistFeature,
    TxFeeFeatureV3
{
    function initialize(
        string calldata name_,
        string calldata symbol_,
        uint8 decimals_,
        uint256 amount_,
        uint256 txFee,
        address txFeeBeneficiary
    ) external virtual initializer {
        __ERC20Base_init(name_, symbol_, decimals_, amount_);
        __BlacklistFeature_init_unchained();
        __PausableWithWhitelistFeature_init_unchained();
        __ERC20TxFeeFeature_init_unchained(txFee, txFeeBeneficiary);
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
    )
        internal
        virtual
        override(BlacklistFeature, PausableWithWhitelistFeature, TxFeeFeatureV3)
    {
        BlacklistFeature._beforeTokenTransfer_hook(from, to, amount);
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

    function transfer(address recipient, uint256 amount)
        public
        virtual
        override(TxFeeFeatureV3, ERC20Upgradeable)
        returns (bool)
    {
        return TxFeeFeatureV3.transfer(recipient, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override(TxFeeFeatureV3, ERC20Upgradeable) returns (bool) {
        return TxFeeFeatureV3.transferFrom(sender, recipient, amount);
    }
}