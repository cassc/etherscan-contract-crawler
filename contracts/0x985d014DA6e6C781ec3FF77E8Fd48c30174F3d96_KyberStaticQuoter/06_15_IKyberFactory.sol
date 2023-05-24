// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;


interface IKyberFactory {

    /// @notice Fetches the recipient of government fees
    /// and current government fee charged in fee units
    function feeConfiguration() external view returns (address _feeTo, uint24 _governmentFeeUnits);
    function getPool(address, address, uint24) external view returns (address);
}