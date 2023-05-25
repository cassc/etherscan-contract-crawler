// SPDX-License-Identifier: AGPL-3.0-or-later
// Just an interface for Dai's permits
pragma solidity ^0.8.17;
abstract contract IPermitDai {
    function permit(address holder, address spender, uint256 nonce, uint256 expiry, bool allowed, uint8 v, bytes32 r, bytes32 s) external virtual;
    // Defining details for checking
    function PERMIT_TYPEHASH() public virtual returns (bytes32);
    function nonces(address) public virtual returns (uint256);
}