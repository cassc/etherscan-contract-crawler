//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import "solmate/src/utils/SafeTransferLib.sol";

library TransferLib {
    using SafeTransferLib for ERC20;

    error ZeroAddress(address payer, address to);

    function transferOut(ERC20 token, address payer, address to, uint256 amount) internal returns (uint256) {
        if (payer == address(0) || to == address(0)) {
            revert ZeroAddress(payer, to);
        }

        // If we are the payer, it's because the funds where transferred first or it was WETH wrapping
        payer == address(this) ? token.safeTransfer(to, amount) : token.safeTransferFrom(payer, to, amount);

        return amount;
    }
}