// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {ISignatureTransfer} from "./ISignatureTransfer.sol";

interface IPermit2 is ISignatureTransfer {
    function permitTransferFrom(
        PermitTransferFrom memory permit,
        SignatureTransferDetails calldata transferDetails,
        address owner,
        bytes calldata signature
    ) external;
}