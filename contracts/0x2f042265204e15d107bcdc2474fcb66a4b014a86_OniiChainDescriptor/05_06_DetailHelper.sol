// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import {Strings} from "./Strings.sol";

/// @title Helper for details generation
library DetailHelper {
    /// @notice Call the library item function
    /// @param lib The library address
    /// @param id The item ID
    function getDetailSVG(address lib, uint8 id)
        internal
        view
        returns (string memory)
    {
        (bool success, bytes memory data) = lib.staticcall(
            abi.encodeWithSignature(
                string(abi.encodePacked("item_", Strings.toString(id), "()"))
            )
        );
        require(success);
        return abi.decode(data, (string));
    }

    /// @notice Generate a random number and return the index from the
    ///         corresponding interval.
    /// @param max The maximum value to generate
    /// @param seed Used for the initialization of the number generator
    /// @param intervals the intervals
    /// @param tokenId the current tokenId
    function generate(
        uint256 max,
        uint256 seed,
        uint256[] memory intervals,
        uint256 tokenId
    ) internal pure returns (uint8) {
        uint256 generated = (uint256(
            keccak256(abi.encodePacked(seed, tokenId))
        ) % (max + 1)) + 1;
        return pickItems(generated, intervals);
    }

    /// @notice Pick an item for the given random value
    /// @param val The random value
    /// @param intervals The intervals for the corresponding items
    /// @return the item ID where : intervals[] index + 1 = item ID
    function pickItems(uint256 val, uint256[] memory intervals)
        internal
        pure
        returns (uint8)
    {
        require(intervals.length <= type(uint8).max, "INTERVAL_NOT_8BITS");

        for (uint256 i; i < intervals.length; i++) {
            if (val > intervals[i]) {
                return uint8(i + 1);
            }
        }
        revert("DetailHelper::pickItems: No item");
    }
}