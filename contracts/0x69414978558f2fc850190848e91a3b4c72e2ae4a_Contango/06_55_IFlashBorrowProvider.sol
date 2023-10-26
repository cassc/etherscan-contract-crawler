//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { IERC20Metadata as IERC20 } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IFlashBorrowProvider {

    error InvalidSenderOrInitiator();

    /// @dev Requests a flash borrow.
    /// @param asset The address of the asset to flash-borrow
    /// @param amount The amount to flash-borrow
    /// @param params Bytes parameters to be passed to the callback
    /// @param callback The callback function to be called after the flash loan
    /// @return result The result of the callback
    function flashBorrow(
        IERC20 asset,
        uint256 amount,
        bytes calldata params,
        /// @dev callback
        /// @param asset Borrowed asset
        /// @param amountOwed The amount to be paid for the flash loan borrowed
        /// @param params The params forwarded to the callback
        /// @return result ABI encoded result of the callback
        function(IERC20, uint256, bytes memory) external returns (bytes memory) callback
    ) external returns (bytes memory result);

}