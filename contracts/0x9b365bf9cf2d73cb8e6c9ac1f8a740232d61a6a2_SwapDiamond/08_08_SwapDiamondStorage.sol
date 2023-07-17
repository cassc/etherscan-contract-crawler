// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract SwapDiamondStorage {
    bytes32 public constant SWAP_DIAMOND_STORAGE_SLOT =
        keccak256("diamond.standard.swapdiamond.storage");

    enum SelectorType {
        Undefined,
        SwapDiamond,
        MasterRouter
    }

    struct SDStorage {
        mapping(bytes4 => SelectorType) selectorTypes;
    }

    function getSelectorType(bytes4 selector_) public view returns (SelectorType selectorType_) {
        return _getSwapDiamondStorage().selectorTypes[selector_];
    }

    function _getSwapDiamondStorage() internal pure returns (SDStorage storage _ds) {
        bytes32 slot_ = SWAP_DIAMOND_STORAGE_SLOT;

        assembly {
            _ds.slot := slot_
        }
    }
}