//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.18;
import "../interfaces/IERC2612.sol";
import "../interfaces/IDAI.sol";

/// @title PermitHelper
/// @dev Helper methods for using ERC20 Permit (ERC2612 or DAI/CHAI like)
library PermitHelper {
    struct Permit {
        uint256 value;
        uint256 nonce;
        uint256 deadline;
        bool isDaiStylePermit;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    /// @dev permit method helper that will handle both known implementations
    // DAI vs ERC2612 tokens
    /// @param permitData bytes containing the encoded permit signature
    /// @param tokenAddress address of the token that will be permitted
    /// @param holder address that holds the tokens to be permitted
    /// @param spender address that will be permitted to spend the tokens
    function permit(
        Permit memory permitData,
        address tokenAddress,
        address holder,
        address spender
    ) internal {
        if (permitData.isDaiStylePermit) {
            IDAI(tokenAddress).permit(
                holder,
                spender,
                permitData.nonce,
                permitData.deadline,
                true,
                permitData.v,
                permitData.r,
                permitData.s
            );
        } else {
            IERC2612(tokenAddress).permit(
                holder,
                spender,
                permitData.value,
                permitData.deadline,
                permitData.v,
                permitData.r,
                permitData.s
            );
        }
    }
}