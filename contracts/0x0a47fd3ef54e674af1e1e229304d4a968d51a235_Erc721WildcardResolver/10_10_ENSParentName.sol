// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

library ENSParentName {
    /**
     * @dev Finds the parent name of a given ENS name, or the empty string if there is no parent.
     *      Assumes the given name is already a well-formed ENS name, and does not check for invalid input.
     * @param name A DNS-encoded name, e.g. 0x03666f6f03626172047465737400 for the name `foo.bar.test`
     * @return child The UTF8-encoded child label, e.g. 0x666f6f for `foo`
     * @return parent The DNS-encoded parent, e.g. 03626172047465737400 for `bar.test`
     */
    function splitParentChildNames(
        bytes calldata name
    ) internal pure returns (bytes calldata child, bytes calldata parent) {
        uint8 labelLength = uint8(name[0]);
        return (name[1:labelLength + 1], name[labelLength + 1:]);
    }
}