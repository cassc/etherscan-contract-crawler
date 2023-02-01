// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

interface IStructNonceManager {
    function nonceConsumed(uint256 nonce) external view returns (bool);
    function requireNonceState(uint256 nonce, bool consumed) external view;
    function consumeNonce(uint256 nonce) external payable;
}