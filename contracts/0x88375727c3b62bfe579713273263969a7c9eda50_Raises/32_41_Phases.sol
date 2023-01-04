// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Raise, Phase} from "../structs/Raise.sol";

/// @title Phases - Raise schedule calculator
/// @notice Calculates a raise's "phase" based on the current timestamp and the
/// raise's configured schedule.
library Phases {
    function phase(Raise memory raise) internal view returns (Phase) {
        // If it's before presale start, the raise is scheduled
        if (block.timestamp < raise.timestamps.presaleStart) {
            return Phase.Scheduled;
        }
        // If it's after public sale end, the raise has ended
        if (block.timestamp > raise.timestamps.publicSaleEnd) {
            return Phase.Ended;
        }
        // We are somewhere between presale start and public sale end.
        if (block.timestamp >= raise.timestamps.publicSaleStart) {
            // If it's after public sale start, we are in public sale.
            return Phase.PublicSale;
        } else {
            // Presale and public sale might not be continuous, so we may return
            // to the scheduled phase...
            if (block.timestamp > raise.timestamps.presaleEnd) {
                // If it's after presale end, we are back in scheduled.
                return Phase.Scheduled;
            } else {
                // Otherwise, we must be in presale.
                return Phase.Presale;
            }
        }
    }
}