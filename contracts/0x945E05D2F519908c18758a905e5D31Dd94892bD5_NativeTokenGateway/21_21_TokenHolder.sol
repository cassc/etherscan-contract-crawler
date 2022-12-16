// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../dependencies/openzeppelin/token/ERC20/utils/SafeERC20.sol";

error FallbackIsNotAllowed();
error ReceiveIsNotAllowed();

/**
 * @title Utils contract that handles tokens sent to it
 */
abstract contract TokenHolder {
    using SafeERC20 for IERC20;

    /**
     * @dev Revert fallback calls
     */
    fallback() external payable {
        revert FallbackIsNotAllowed();
    }

    /**
     * @dev Revert when receiving by default
     */
    receive() external payable virtual {
        revert ReceiveIsNotAllowed();
    }

    /**
     * @notice ERC20 recovery in case of stuck tokens due direct transfers to the contract address.
     * @param token_ The token to transfer
     * @param to_ The recipient of the transfer
     * @param amount_ The amount to send
     */
    function sweep(
        IERC20 token_,
        address to_,
        uint256 amount_
    ) external {
        _requireCanSweep();

        if (address(token_) == address(0)) {
            Address.sendValue(payable(to_), amount_);
        } else {
            token_.safeTransfer(to_, amount_);
        }
    }

    /**
     * @notice Function that reverts if the caller isn't allowed to sweep tokens
     * @dev Usually requires the owner or governor as the caller
     */
    function _requireCanSweep() internal view virtual;
}