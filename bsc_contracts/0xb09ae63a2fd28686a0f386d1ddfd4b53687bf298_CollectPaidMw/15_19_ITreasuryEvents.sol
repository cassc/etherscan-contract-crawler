// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { DataTypes } from "../libraries/DataTypes.sol";

interface ITreasuryEvents {
    /**
     * @notice Emitted when a currency has been allowed.
     *
     * @param currency The ERC20 token contract address.
     * @param preAllowed The previously allow state.
     * @param newAllowed The newly set allow state.
     */
    event AllowCurrency(
        address indexed currency,
        bool indexed preAllowed,
        bool indexed newAllowed
    );

    /**
     * @notice Emitted when a new treasuryAddress has been set.
     *
     * @param preTreasuryAddress The previous treasuryAddress.
     * @param treasuryAddress The new treasuryAddress.
     */
    event SetTreasuryAddress(
        address indexed preTreasuryAddress,
        address indexed treasuryAddress
    );

    /**
     * @notice Emitted when a new treasuryFee has been set.
     *
     * @param preTreasuryFee The previous treasuryFee.
     * @param treasuryFee The new treasuryFee.
     */
    event SetTreasuryFee(
        uint16 indexed preTreasuryFee,
        uint16 indexed treasuryFee
    );
}