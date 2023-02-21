// SPDX-License-Identifier: MIT
// Heavily inspired by:
// OpenZeppelin Contracts v4.4.1 (token/Delegate/extensions/draft-ERC20Permit.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

/**
 * @dev Abstract contract including helper functions to allow delegation by signature using
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {_verifyDelegatePermit} internal method, verifies a signature specifying permission to receive delegation power
 *
 */
abstract contract DelegatePermit is EIP712 {
    using Counters for Counters.Counter;

    mapping(address => Counters.Counter) private _nonces;

    // solhint-disable-next-line var-name-mixedcase
    bytes32 private constant _DELEGATE_TYPEHASH =
        keccak256(
            "Delegate(address delegator,address delegatee,uint256 nonce,uint256 deadline)"
        );

    /**
     * @notice Verify that the given delegate signature is valid, throws if not
     * @param delegator The address delegating
     * @param delegatee The address being delegated to
     * @param deadline The deadling of the delegation after which it will be invalid
     * @param v The v part of the signature
     * @param r The r part of the signature
     * @param s The s part of the signature
     */
    function _verifyDelegatePermit(
        address delegator,
        address delegatee,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        require(
            block.timestamp <= deadline,
            "DelegatePermit: expired deadline"
        );
        require(delegator != address(0), "invalid delegator");

        bytes32 structHash = keccak256(
            abi.encode(
                _DELEGATE_TYPEHASH,
                delegator,
                delegatee,
                _useDelegationNonce(delegator),
                deadline
            )
        );

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSA.recover(hash, v, r, s);
        require(signer == delegator, "DelegatePermit: invalid signature");
    }

    /**
     * @notice get the current nonce for the given address
     * @param owner The address to get nonce for
     * @return the current nonce of `owner`
     */
    function delegationNonce(address owner) public view returns (uint256) {
        return _nonces[owner].current();
    }

    /**
     * @dev "Consume a nonce": return the current value and increment.
     *
     * _Available since v4.1._
     */
    function _useDelegationNonce(address owner)
        private
        returns (uint256 current)
    {
        Counters.Counter storage nonce = _nonces[owner];
        current = nonce.current();
        nonce.increment();
    }
}