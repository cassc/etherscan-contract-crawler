// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import { AltitudeBase } from "../utils/AltitudeBase.sol";

interface ISnowPatrol {
    function ADMIN_ROLE() external pure returns (bytes32);
    function LGE_ROLE() external pure returns (bytes32);
    function PWDR_ROLE() external pure returns (bytes32);
    function SLOPES_ROLE() external pure returns (bytes32);
    function setCoreRoles() external;
}