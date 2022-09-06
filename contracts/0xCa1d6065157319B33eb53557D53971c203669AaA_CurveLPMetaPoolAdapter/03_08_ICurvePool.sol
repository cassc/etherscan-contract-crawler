// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

// solhint-disable

interface ICurvePool {
    function get_virtual_price() external view returns (uint256);

    function balances(uint256 arg0) external view returns (uint256);

    function price_oracle(uint256) external view returns (uint256);
}