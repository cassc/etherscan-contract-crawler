// SPDX-License-Identifier: LGPL-3.0

pragma solidity 0.8.17;

import {SignatureTransfer} from "light-permit2/contracts/SignatureTransfer.sol";
import {AllowanceTransfer} from "light-permit2/contracts/AllowanceTransfer.sol";

/// @notice Permit2 handles signature-based transfers in SignatureTransfer and allowance-based transfers in AllowanceTransfer.
/// @dev Users must approve Permit2 before calling any of the transfer functions.
contract Permit2 is SignatureTransfer, AllowanceTransfer {
    // Permit2 unifies the two contracts so users have maximal flexibility with their approval.
}