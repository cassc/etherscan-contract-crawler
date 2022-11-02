// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

abstract contract Owned {
	address public owner;
	address public nominatedOwner;

	mapping(address => bool) public workers;

	error AlreadyRole();
	error NotRole();
	error Unauthorized();

	constructor(address _owner) {
		owner = _owner;
		nominatedOwner = _owner;
		workers[msg.sender] = true;
	}

	function nominateOwner(address _nominatedOwner) external onlyOwner {
		nominatedOwner = _nominatedOwner;
	}

	function acceptOwner() external {
		if (msg.sender != nominatedOwner) revert Unauthorized();
		if (msg.sender == owner) revert AlreadyRole();
		owner = msg.sender;
	}

	function addWorker(address _worker) external {
		if (workers[_worker]) revert AlreadyRole();
		workers[_worker] = true;
	}

	function removeWorker(address _worker) external {
		if (!workers[_worker]) revert NotRole();
		workers[_worker] = false;
	}

	modifier onlyOwner() {
		if (msg.sender != owner) revert Unauthorized();
		_;
	}

	modifier onlyAuthorized() {
		if (msg.sender != owner && !workers[msg.sender]) revert Unauthorized();
		_;
	}
}