//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

/// @title Report Bounds Storage
/// @notice Utility to manage the Report Bounds in storage
library ReportBounds {
    /// @notice Storage slot of the Report Bounds
    bytes32 internal constant REPORT_BOUNDS_SLOT = bytes32(uint256(keccak256("river.state.reportBounds")) - 1);

    /// @notice The Report Bounds structure
    struct ReportBoundsStruct {
        /// @custom:attribute The maximum allowed annual apr, checked before submitting a report to River
        uint256 annualAprUpperBound;
        /// @custom:attribute The maximum allowed balance decrease, also checked before submitting a report to River
        uint256 relativeLowerBound;
    }

    /// @notice The structure in storage
    struct Slot {
        /// @custom:attribute The structure in storage
        ReportBoundsStruct value;
    }

    /// @notice Retrieve the Report Bounds from storage
    /// @return The Report Bounds
    function get() internal view returns (ReportBoundsStruct memory) {
        bytes32 slot = REPORT_BOUNDS_SLOT;

        Slot storage r;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            r.slot := slot
        }

        return r.value;
    }

    /// @notice Set the Report Bounds in storage
    /// @param _newReportBounds The new Report Bounds value
    function set(ReportBoundsStruct memory _newReportBounds) internal {
        bytes32 slot = REPORT_BOUNDS_SLOT;

        Slot storage r;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            r.slot := slot
        }

        r.value = _newReportBounds;
    }
}