// SPDX-License-Identifier: MIT
pragma solidity =0.8.6;

import "@openzeppelin/contracts/utils/Timers.sol";

interface IAllocator {

    struct Allocation {
        address allocator;
        uint256 amount;
    }

    struct Phase {
        Timers.BlockNumber block;
        uint256 mintLimit;
    }

    event MaxBaseAllocation(uint256 amount);
    event MaxAllocation(address indexed allocator, uint256 amount);
    event CurrentAllocation(address indexed allocator, uint256 amount);
    event PhaseSet(uint256 indexed id, uint64 deadline, uint256 limit);
    event AllocatorSet(bool status);

    function setAllocatorActive(bool active) external;

    function isAllocatorActive() external view returns (bool);

    function currentAllocation(address allocator) external view returns(uint256);

    function maximumAllocation(address allocator) external view returns(uint256);

    function totalAllocationLimit() external view returns(uint256);

    function setAllocations(Allocation[] memory allocances) external;

    function setBaseAllocation(uint256 amount) external;

    function setAllocation(address allocator, uint256 amount) external;

    function canAllocate(address allocator, uint256 amount) external view returns(bool, string memory);

    function setPhases(Phase[] memory phases) external;

    function insertPhase(Phase memory phase) external;

    function updatePhase(uint256 phaseId, uint64 timestamp, uint256 minLimit) external;

    function getPhases() external view returns(Phase[] memory);

    function getCurrentPhaseLimit() external view returns(uint256);

    function allocate(address allocator, uint256 amount) external;
}