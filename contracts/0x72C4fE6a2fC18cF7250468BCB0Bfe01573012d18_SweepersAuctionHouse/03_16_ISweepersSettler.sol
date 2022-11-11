// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface ISweepersSettler {
    function currentFee() external view returns (uint256);
}