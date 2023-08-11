// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {ILenderVerifier} from "../interfaces/ILenderVerifier.sol";
import {IGlobalWhitelistLenderVerifier} from "../ragnarok/interfaces/IGlobalWhitelistLenderVerifier.sol";

contract GlobalWhitelistLenderVerifierWrapper is ILenderVerifier {
    IGlobalWhitelistLenderVerifier public immutable globalWhitelistLenderVerifier;

    constructor(IGlobalWhitelistLenderVerifier _globalWhitelistLenderVerifier) {
        globalWhitelistLenderVerifier = _globalWhitelistLenderVerifier;
    }

    function isAllowed(address lender) external view returns (bool) {
        return globalWhitelistLenderVerifier.isAllowed(lender, 0, new bytes(0));
    }
}