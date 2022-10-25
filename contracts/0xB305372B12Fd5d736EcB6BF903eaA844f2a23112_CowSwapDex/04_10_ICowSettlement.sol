// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.17;

/// @notice Gnosis Protocol v2 Settlement Interface.
interface ICowSettlement {
    function setPreSignature(bytes calldata orderUid, bool signed) external;
}