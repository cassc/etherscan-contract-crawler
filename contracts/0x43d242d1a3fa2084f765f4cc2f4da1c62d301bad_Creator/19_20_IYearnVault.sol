// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.13;

interface IYearnVault {
    function pricePerShare() external view returns (uint256);

    /// @dev The address of the underlying asset
    function token() external view returns (address);
}