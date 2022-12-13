// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/interfaces/IERC20Transferable.sol";
import "contracts/libraries/errors/ERC20SafeTransferErrors.sol";

abstract contract ERC20SafeTransfer {
    // _safeTransferFromERC20 performs a transferFrom call against an erc20 contract in a safe manner
    // by reverting on failure
    // this function will return without performing a call or reverting
    // if amount_ is zero
    function _safeTransferFromERC20(
        IERC20Transferable contract_,
        address sender_,
        uint256 amount_
    ) internal {
        if (amount_ == 0) {
            return;
        }
        if (address(contract_) == address(0x0)) {
            revert ERC20SafeTransferErrors.CannotCallContractMethodsOnZeroAddress();
        }

        bool success = contract_.transferFrom(sender_, address(this), amount_);
        if (!success) {
            revert ERC20SafeTransferErrors.Erc20TransferFailed(
                address(contract_),
                sender_,
                address(this),
                amount_
            );
        }
    }

    // _safeTransferERC20 performs a transfer call against an erc20 contract in a safe manner
    // by reverting on failure
    // this function will return without performing a call or reverting
    // if amount_ is zero
    function _safeTransferERC20(
        IERC20Transferable contract_,
        address to_,
        uint256 amount_
    ) internal {
        if (amount_ == 0) {
            return;
        }
        if (address(contract_) == address(0x0)) {
            revert ERC20SafeTransferErrors.CannotCallContractMethodsOnZeroAddress();
        }
        bool success = contract_.transfer(to_, amount_);
        if (!success) {
            revert ERC20SafeTransferErrors.Erc20TransferFailed(
                address(contract_),
                address(this),
                to_,
                amount_
            );
        }
    }
}