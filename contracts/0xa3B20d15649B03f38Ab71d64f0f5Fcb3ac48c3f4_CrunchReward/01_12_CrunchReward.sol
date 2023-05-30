// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./access/HasCrunchParent.sol";
import "./CrunchToken.sol";

contract CrunchReward is HasCrunchParent {
    constructor(CrunchToken crunch) HasCrunchParent(crunch) {}

    /**
     * @dev Distribute tokens.
     *
     * Requirements:
     *
     * - `recipients` and `values` are the same length.
     * - the reserve has enough to cover the sum of `values`.
     */
    function distribute(address[] memory recipients, uint256[] memory values)
        public
        onlyOwner
    {
        require(
            recipients.length == values.length,
            "recipients and values length differ"
        );

        require(recipients.length != 0, "must at least have one target");

        require(
            reserve() >= sum(values),
            "the reserve does not have enough token"
        );

        for (uint256 index = 0; index < recipients.length; index++) {
            crunch.transfer(recipients[index], values[index]);
        }
    }

    /**
     * @dev Empty the contract token and transfer them to the owner.
     *
     * Requirements:
     *
     * - `reserve()` must not be zero.
     */
    function empty() public onlyOwner {
        bool success = _transferRemaining();

        require(success, "already empty");
    }

    /** @dev Destroy the contract and transfer. */
    function destroy() public onlyOwner {
        _transferRemaining();

        selfdestruct(payable(owner()));
    }

    /** @dev Returns the current balance of the contract. */
    function reserve() public view returns (uint256) {
        return crunch.balanceOf(address(this));
    }

    /** @dev Returns the sum of each value in `values`. */
    function sum(uint256[] memory values)
        internal
        pure
        returns (uint256 accumulator)
    {
        for (uint256 index = 0; index < values.length; index++) {
            accumulator += values[index];
        }
    }

    function _transferRemaining() internal returns (bool success) {
        uint256 remaining = reserve();

        if (remaining != 0) {
            crunch.transfer(owner(), remaining);
            return true;
        }

        return false;
    }
}