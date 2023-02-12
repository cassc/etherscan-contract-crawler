// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library TrackableBurnableERC1155Storage {
    struct Layout {
        /// @dev Token name
        string name;
        /// @dev Token symbol
        string symbol;
        /// @dev Total supply for each token
        mapping(uint256 => uint256) totalSupply;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256(
            "trackableburnableerc1155.contracts.storage.trackableburnableerc1155"
        );

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}