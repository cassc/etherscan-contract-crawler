// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";

contract NotesProxyFactory {

	address public implementationContract;
	address[] public allClones;
	mapping(address => address) public noteClones;

	event NewClone(address _clone);

	constructor(address _implementation) {
		implementationContract = _implementation;
	}


	function createNew() payable external returns(address instance) {
		instance = ClonesUpgradeable.clone(implementationContract);

		(bool success, ) = instance.call{value: msg.value}(abi.encodeWithSignature("initialize(address)", msg.sender));

		allClones.push(instance);
		noteClones[msg.sender] = instance;
		emit NewClone(instance);
		return instance;
	}
}