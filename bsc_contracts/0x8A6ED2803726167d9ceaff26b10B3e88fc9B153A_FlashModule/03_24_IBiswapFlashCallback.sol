// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IBiswapFlashCallback {

    /// @notice Call the msg.sender after sending tokens in IBiswapPoolV3#flash.
    /// @dev Must repay the tokens to the pool within one call.
    /// @param feeX the fee amount in tokenX due to the pool by the end of the flash
    /// @param feeY the fee amount in tokenY due to the pool by the end of the flash
    /// @param data any data passed through by the caller
    function flashCallback(
        uint256 feeX,
        uint256 feeY,
        bytes calldata data
    ) external;

}