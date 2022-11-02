//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "./Admin.sol";
import "./BridgeOut.sol";
import "./BridgeIn.sol";
import "./Governance.sol";

/// @title Bridge allowing transfer of tokens (both fungible and non-fungible)
/// to/from GalaChain. The bridge can operate in two mods: locking or burning and depending on the mode
/// the tokens will either be locked/burnt or released/minted. For a locking bridge, if the bridge doesn't hold
/// enough tokens to release, it can mint the missing amount.
/// @author Piotr Buda
contract Bridge is Admin, Governance, BridgeOut, BridgeIn {
    constructor() initializer {}
}