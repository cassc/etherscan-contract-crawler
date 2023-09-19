pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

import "ProjectInfo.sol";

bytes1 constant NOT_ACTIVE = 0x00;
bytes1 constant ACTIVE = 0x01;
bytes1 constant MARKET_UNAVAILABLE = 0x02;
bytes1 constant CLOSED = 0x03;
bytes1 constant PAUSED = 0x04;


abstract contract IProjectMan {
    mapping(uint32 => ProjectInfo) internal _projects;

    function projectExists(uint32 projectId) public virtual view returns (bool);
    function getProject(uint32 projectId) public virtual view returns (ProjectInfo memory);
}