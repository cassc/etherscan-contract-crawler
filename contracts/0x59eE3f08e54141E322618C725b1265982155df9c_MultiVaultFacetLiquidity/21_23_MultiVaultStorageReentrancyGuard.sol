// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.0;


//import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
library MultiVaultStorageReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 constant _NOT_ENTERED = 1;
    uint256 constant _ENTERED = 2;

    bytes32 constant REENTRANCY_GUARD_LEGACY_STORAGE_POSITION = 0x0000000000000000000000000000000000000000000000000000000000000001;

    struct ReentrancyGuardStorage {
        uint256 _status;
    }

    function _storage() internal pure returns (ReentrancyGuardStorage storage s) {
        assembly {
            s.slot := REENTRANCY_GUARD_LEGACY_STORAGE_POSITION
        }
    }
}