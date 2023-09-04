// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../interfaces/IOmniseaDropsRepository.sol";

contract OmniseaDropsFactory is ReentrancyGuard {
    address public repository;
    address private owner;

    constructor() {
        owner = msg.sender;
    }

    function setRepository(address repo) external {
        require(msg.sender == owner && repo != address(0));
        repository = repo;
    }

    function create(CreateParams calldata _params) external nonReentrant {
        require(_params.endTime > block.timestamp);

        IOmniseaDropsRepository(repository).create(_params, msg.sender);
    }
}