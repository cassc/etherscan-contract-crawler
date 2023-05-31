// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import {WaterfallModule} from "./WaterfallModule.sol";
import {LibClone} from "solady/utils/LibClone.sol";

/// @title WaterfallModuleFactory
/// @author 0xSplits
/// @notice A factory contract for cheaply deploying WaterfallModules.
/// @dev This contract uses token = address(0) to refer to ETH.
contract WaterfallModuleFactory {
    /// -----------------------------------------------------------------------
    /// errors
    /// -----------------------------------------------------------------------

    /// Invalid number of recipients, must have at least 2
    error InvalidWaterfall__TooFewRecipients();

    /// Invalid recipient & threshold lengths; recipients must have one more
    /// entry than thresholds
    error InvalidWaterfall__RecipientsAndThresholdsLengthMismatch();

    /// Thresholds must be positive
    error InvalidWaterfall__ZeroThreshold();

    /// Invalid threshold at `index`; must be < 2^96
    /// @param index Index of too-large threshold
    error InvalidWaterfall__ThresholdTooLarge(uint256 index);

    /// Invalid threshold at `index` (thresholds must increase monotonically)
    /// @param index Index of out-of-order threshold
    error InvalidWaterfall__ThresholdsOutOfOrder(uint256 index);

    /// -----------------------------------------------------------------------
    /// libraries
    /// -----------------------------------------------------------------------

    using LibClone for address;

    /// -----------------------------------------------------------------------
    /// events
    /// -----------------------------------------------------------------------

    /// Emitted after a new waterfall module is deployed
    /// @param waterfallModule Address of newly created WaterfallModule clone
    /// @param token Address of ERC20 to waterfall (0x0 used for ETH)
    /// @param nonWaterfallRecipient Address to recover non-waterfall tokens to
    /// @param recipients Addresses to waterfall payments to
    /// @param thresholds Absolute payment thresholds for waterfall recipients
    /// (last recipient has no threshold & receives all residual flows)
    event CreateWaterfallModule(
        address indexed waterfallModule,
        address token,
        address nonWaterfallRecipient,
        address[] recipients,
        uint256[] thresholds
    );

    /// -----------------------------------------------------------------------
    /// storage
    /// -----------------------------------------------------------------------

    uint256 internal constant ADDRESS_BITS = 160;

    /// WaterfallModule implementation address
    WaterfallModule public immutable wmImpl;

    /// -----------------------------------------------------------------------
    /// constructor
    /// -----------------------------------------------------------------------

    constructor() {
        wmImpl = new WaterfallModule();
    }

    /// -----------------------------------------------------------------------
    /// functions
    /// -----------------------------------------------------------------------

    /// -----------------------------------------------------------------------
    /// functions - public & external
    /// -----------------------------------------------------------------------

    /// Create a new WaterfallModule clone
    /// @param token Address of ERC20 to waterfall (0x0 used for ETH)
    /// @param nonWaterfallRecipient Address to recover non-waterfall tokens to
    /// @param recipients Addresses to waterfall payments to
    /// @param thresholds Absolute payment thresholds for waterfall recipients
    /// (last recipient has no threshold & receives all residual flows)
    /// @return wm Address of new WaterfallModule clone
    function createWaterfallModule(
        address token,
        address nonWaterfallRecipient,
        address[] calldata recipients,
        uint256[] calldata thresholds
    ) external returns (WaterfallModule wm) {
        /// checks

        // cache lengths for re-use
        uint256 recipientsLength = recipients.length;
        uint256 thresholdsLength = thresholds.length;

        // ensure recipients array has at least 2 entries
        if (recipientsLength < 2) {
            revert InvalidWaterfall__TooFewRecipients();
        }
        // ensure recipients array is one longer than thresholds array
        unchecked {
            // shouldn't underflow since _recipientsLength >= 2
            if (thresholdsLength != recipientsLength - 1) {
                revert InvalidWaterfall__RecipientsAndThresholdsLengthMismatch();
            }
        }
        // ensure first threshold isn't zero
        if (thresholds[0] == 0) {
            revert InvalidWaterfall__ZeroThreshold();
        }
        // ensure first threshold isn't too large
        if (thresholds[0] > type(uint96).max) {
            revert InvalidWaterfall__ThresholdTooLarge(0);
        }
        // ensure packed thresholds increase monotonically
        uint256 i = 1;
        for (; i < thresholdsLength;) {
            if (thresholds[i] > type(uint96).max) {
                revert InvalidWaterfall__ThresholdTooLarge(i);
            }
            unchecked {
                // shouldn't underflow since i >= 1
                if (thresholds[i - 1] >= thresholds[i]) {
                    revert InvalidWaterfall__ThresholdsOutOfOrder(i);
                }
                // shouldn't overflow
                ++i;
            }
        }

        /// effects

        // copy recipients & thresholds into storage
        i = 0;
        uint256[] memory tranches = new uint256[](recipientsLength);
        for (; i < thresholdsLength;) {
            tranches[i] = (thresholds[i] << ADDRESS_BITS)
                | uint256(uint160(recipients[i]));
            unchecked {
                // shouldn't overflow
                ++i;
            }
        }
        // recipients array is one longer than thresholds array; set last item after loop
        tranches[i] = uint256(uint160(recipients[i]));

        // recipientsLength won't realistically be > 2^64; deployed contract
        // would exceed contract size limits
        bytes memory data = abi.encodePacked(
            token, nonWaterfallRecipient, uint64(recipientsLength), tranches
        );
        wm = WaterfallModule(address(wmImpl).clone(data));
        emit CreateWaterfallModule(
            address(wm), token, nonWaterfallRecipient, recipients, thresholds
            );
    }
}