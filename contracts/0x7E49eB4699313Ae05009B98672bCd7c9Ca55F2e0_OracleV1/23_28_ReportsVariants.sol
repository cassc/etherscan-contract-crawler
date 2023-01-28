//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

/// @title Reports Variants Storage
/// @notice Utility to manage the Reports Variants in storage
library ReportsVariants {
    /// @notice Storage slot of the Reports Variants
    bytes32 internal constant REPORTS_VARIANTS_SLOT = bytes32(uint256(keccak256("river.state.reportsVariants")) - 1);

    /// @notice Mask used to extra the report values from the variant
    /// @notice This is the packing done inside the variant in storage
    /// @notice
    /// @notice [ 0,  16) : <voteCount>           oracle member's total vote count for the numbers below (uint16, 2 bytes)
    /// @notice [16,  48) : <beaconValidators>    total number of beacon validators (uint32, 4 bytes)
    /// @notice [48, 112) : <beaconBalance>       total balance of all the beacon validators (uint64, 6 bytes)
    /// @notice
    /// @notice So applying this mask, we can extra the voteCount out to perform comparisons on the report values
    /// @notice
    /// @notice xx...xx <beaconBalance> <beaconValidators> xxxx & COUNT_OUTMASK  ==
    /// @notice 00...00 <beaconBalance> <beaconValidators> 0000
    uint256 internal constant COUNT_OUTMASK = 0xFFFFFFFFFFFFFFFFFFFFFFFF0000;

    /// @notice Structure in storage
    struct Slot {
        /// @custom:attribute The list of variants
        uint256[] value;
    }

    /// @notice Retrieve the Reports Variants from storage
    /// @return The Reports Variants
    function get() internal view returns (uint256[] memory) {
        bytes32 slot = REPORTS_VARIANTS_SLOT;

        Slot storage r;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            r.slot := slot
        }

        return r.value;
    }

    /// @notice Set the Reports Variants value at index
    /// @param _idx The index to set
    /// @param _val The value to set
    function set(uint256 _idx, uint256 _val) internal {
        bytes32 slot = REPORTS_VARIANTS_SLOT;

        Slot storage r;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            r.slot := slot
        }

        r.value[_idx] = _val;
    }

    /// @notice Add a new variant in the list
    /// @param _variant The new variant to add
    function push(uint256 _variant) internal {
        bytes32 slot = REPORTS_VARIANTS_SLOT;

        Slot storage r;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            r.slot := slot
        }

        r.value.push(_variant);
    }

    /// @notice Retrieve the index of a specific variant, ignoring the count field
    /// @param _variant Variant value to lookup
    /// @return The index of the variant, -1 if not found
    function indexOfReport(uint256 _variant) internal view returns (int256) {
        bytes32 slot = REPORTS_VARIANTS_SLOT;

        Slot storage r;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            r.slot := slot
        }

        for (uint256 idx = 0; idx < r.value.length;) {
            if (r.value[idx] & COUNT_OUTMASK == _variant) {
                return int256(idx);
            }
            unchecked {
                ++idx;
            }
        }

        return int256(-1);
    }

    /// @notice Clear all variants from storage
    function clear() internal {
        bytes32 slot = REPORTS_VARIANTS_SLOT;

        Slot storage r;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            r.slot := slot
        }

        delete r.value;
    }
}