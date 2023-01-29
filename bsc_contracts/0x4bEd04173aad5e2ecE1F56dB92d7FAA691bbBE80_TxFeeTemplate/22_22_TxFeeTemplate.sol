// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../ERC20Base.sol";
import "../features/TxFeeFeatureV3.sol";

contract TxFeeTemplate is ERC20Base, TxFeeFeatureV3 {
    function initialize(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 amount_,
        uint256 txFee,
        address txFeeBeneficiary
    ) public initializer {
        __ERC20Base_init(name_, symbol_, decimals_, amount_);
        __ERC20TxFeeFeature_init_unchained(txFee, txFeeBeneficiary);
    }

    function _beforeTokenTransfer_hook(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(TxFeeFeatureV3) {
        // TxFeeFeatureV3._beforeTokenTransfer_hook(from, to, amount);
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