//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

/// @title Reports Variants Storage
/// @notice Utility to manage the Reports Variants in storage
library ReportsVariants {
    /// @notice Storage slot of the Reports Variants
    bytes32 internal constant REPORT_VARIANTS_SLOT = bytes32(uint256(keccak256("river.state.reportsVariants")) - 1);

    struct ReportVariantDetails {
        bytes32 variant;
        uint256 votes;
    }

    /// @notice Structure in storage
    struct Slot {
        /// @custom:attribute The list of variants
        ReportVariantDetails[] value;
    }

    /// @notice Retrieve the Reports Variants from storage
    /// @return The Reports Variants
    function get() internal view returns (ReportVariantDetails[] storage) {
        bytes32 slot = REPORT_VARIANTS_SLOT;

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
    function set(uint256 _idx, ReportVariantDetails memory _val) internal {
        bytes32 slot = REPORT_VARIANTS_SLOT;

        Slot storage r;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            r.slot := slot
        }

        r.value[_idx] = _val;
    }

    /// @notice Add a new variant in the list
    /// @param _variant The new variant to add
    function push(ReportVariantDetails memory _variant) internal {
        bytes32 slot = REPORT_VARIANTS_SLOT;

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
    function indexOfReport(bytes32 _variant) internal view returns (int256) {
        bytes32 slot = REPORT_VARIANTS_SLOT;

        Slot storage r;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            r.slot := slot
        }

        for (uint256 idx = 0; idx < r.value.length;) {
            if (r.value[idx].variant == _variant) {
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
        bytes32 slot = REPORT_VARIANTS_SLOT;

        Slot storage r;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            r.slot := slot
        }

        delete r.value;
    }
}