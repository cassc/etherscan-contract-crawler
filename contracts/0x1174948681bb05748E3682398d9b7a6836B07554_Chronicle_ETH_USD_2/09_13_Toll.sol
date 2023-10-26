// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {IToll} from "./IToll.sol";

/**
 * @title Toll Module
 *
 * @notice "Toll paid, we kiss - but dissension looms, maybe diss?"
 *
 * @dev The `Toll` contract module provides a basic access control mechanism,
 *      where a set of addresses are granted access to protected functions.
 *      These addresses are said the be _tolled_.
 *
 *      Initially, no address is tolled. Through the `kiss(address)` and
 *      `diss(address)` functions, auth'ed callers are able to toll/de-toll
 *      addresses. Authentication for these functions is defined via the
 *      downstream implemented `toll_auth()` function.
 *
 *      This module is used through inheritance. It will make available the
 *      modifier `toll`, which can be applied to functions to restrict their
 *      use to only tolled callers.
 */
abstract contract Toll is IToll {
    /// @dev Mapping storing whether address is tolled.
    /// @custom:invariant Image of mapping is {0, 1}.
    ///                     ∀x ∊ Address: _buds[x] ∊ {0, 1}
    /// @custom:invariant Only functions `kiss` and `diss` may mutate the mapping's state.
    ///                     ∀x ∊ Address: preTx(_buds[x]) != postTx(_buds[x])
    ///                                     → (msg.sig == "kiss" ∨ msg.sig == "diss")
    /// @custom:invariant Mapping's state may only be mutated by authenticated caller.
    ///                     ∀x ∊ Address: preTx(_buds[x]) != postTx(_buds[x])
    ///                                     → toll_auth()
    mapping(address => uint) private _buds;

    /// @dev List of addresses possibly being tolled.
    /// @dev May contain duplicates.
    /// @dev May contain addresses not being tolled anymore.
    /// @custom:invariant Every address being tolled once is element of the list.
    ///                     ∀x ∊ Address: tolled(x) → x ∊ _budsTouched
    address[] private _budsTouched;

    /// @dev Ensures caller is tolled.
    modifier toll() {
        assembly ("memory-safe") {
            // Compute slot of _buds[msg.sender].
            mstore(0x00, caller())
            mstore(0x20, _buds.slot)
            let slot := keccak256(0x00, 0x40)

            // Revert if caller not tolled.
            let isTolled := sload(slot)
            if iszero(isTolled) {
                // Store selector of `NotTolled(address)`.
                mstore(0x00, 0xd957b595)
                // Store msg.sender.
                mstore(0x20, caller())
                // Revert with (offset, size).
                revert(0x1c, 0x24)
            }
        }
        _;
    }

    /// @dev Reverts if caller not allowed to access protected function.
    /// @dev Must be implemented in downstream contract.
    function toll_auth() internal virtual;

    /// @inheritdoc IToll
    function kiss(address who) external {
        toll_auth();

        if (_buds[who] == 1) return;

        _buds[who] = 1;
        _budsTouched.push(who);
        emit TollGranted(msg.sender, who);
    }

    /// @inheritdoc IToll
    function diss(address who) external {
        toll_auth();

        if (_buds[who] == 0) return;

        _buds[who] = 0;
        emit TollRenounced(msg.sender, who);
    }

    /// @inheritdoc IToll
    function tolled(address who) public view returns (bool) {
        return _buds[who] == 1;
    }

    /// @inheritdoc IToll
    /// @custom:invariant Only contains tolled addresses.
    ///                     ∀x ∊ tolled(): _tolled[x]
    /// @custom:invariant Contains all tolled addresses.
    ///                     ∀x ∊ Address: _tolled[x] == 1 → x ∊ tolled()
    function tolled() public view returns (address[] memory) {
        // Initiate array with upper limit length.
        address[] memory budsList = new address[](_budsTouched.length);

        // Iterate through all possible tolled addresses.
        uint ctr;
        for (uint i; i < budsList.length; i++) {
            // Add address only if still tolled.
            if (_buds[_budsTouched[i]] == 1) {
                budsList[ctr++] = _budsTouched[i];
            }
        }

        // Set length of array to number of tolled addresses actually included.
        assembly ("memory-safe") {
            mstore(budsList, ctr)
        }

        return budsList;
    }

    /// @inheritdoc IToll
    function bud(address who) public view returns (uint) {
        return _buds[who];
    }
}