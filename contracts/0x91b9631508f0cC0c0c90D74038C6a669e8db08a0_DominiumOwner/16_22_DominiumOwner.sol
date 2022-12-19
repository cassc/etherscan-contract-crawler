//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {PartialMultisigWallet} from "./base/PartialMultisigWallet.sol";

/// @title Dominium's owner
/// @author Amit Molek
/// @notice Safer multi-sig based owner for the Dominium system
contract DominiumOwner is PartialMultisigWallet {
    constructor(address[] memory owners) PartialMultisigWallet(owners) {}
}