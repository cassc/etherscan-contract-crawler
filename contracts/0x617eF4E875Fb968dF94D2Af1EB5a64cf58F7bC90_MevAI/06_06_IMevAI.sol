// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IMevAI {
    function checkForMev(address from) external view returns (bool);
}