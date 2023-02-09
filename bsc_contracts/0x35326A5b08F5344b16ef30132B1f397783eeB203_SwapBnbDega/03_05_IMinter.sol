// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface IMinter {
    function PEG_RATIO() external view returns (uint);

    function convertBTCBtoDEGA(uint amount) external;
    function convertBTCBtoDEGAAndDeposit(uint amount) external;
    function convertDEGAtoBTCB(uint amount) external;
}