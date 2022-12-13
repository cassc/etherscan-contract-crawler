// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IBridge {
    function minBonderBps() external view returns (uint256);

    function minBonderFeeAbsolute() external view returns (uint256);
}