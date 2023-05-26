// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface CelestialInterface is IERC20 {

    function isBlocked(address[] memory who) view external returns (bool[] memory);

    function isPermitted(address[] memory who) view external returns (bool[] memory);

    function setBlockList(address[] memory who, bool[] memory flag) external;

    function setPermitList(address[] memory who, bool[] memory flag) external;
}