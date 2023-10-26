// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/concentrated-lps>.
pragma solidity 0.7.6;

library GyroConfigKeys {
    bytes32 public constant PROTOCOL_SWAP_FEE_PERC_KEY = "PROTOCOL_SWAP_FEE_PERC";
    bytes32 public constant PROTOCOL_FEE_GYRO_PORTION_KEY = "PROTOCOL_FEE_GYRO_PORTION";
    bytes32 public constant GYRO_TREASURY_KEY = "GYRO_TREASURY";
    bytes32 public constant BAL_TREASURY_KEY = "BAL_TREASURY";
}