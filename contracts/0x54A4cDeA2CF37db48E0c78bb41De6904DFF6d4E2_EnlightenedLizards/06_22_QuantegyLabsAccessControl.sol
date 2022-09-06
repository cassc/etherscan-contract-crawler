//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import 'hardhat/console.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

contract QuantegyLabsAccessControl is Ownable, ReentrancyGuard {
	/// @dev The CEO's address
	address internal ceoAddress;
	/// @dev The CTO's address
	address internal ctoAddress;
	/// @dev The Quantegy Labs treasury multi-sig address
	address payable internal treasury;

	modifier onlyCEO() {
		require(msg.sender == ceoAddress, 'QuantegyLabsAccessControl: CEO only');
		_;
	}

	modifier onlyCTO() {
		require(msg.sender == ctoAddress, 'QuantegyLabsAccessControl: CTO only');
		_;
	}

	modifier adminOnly() {
		require(msg.sender == ceoAddress || msg.sender == ctoAddress || msg.sender == owner(), 'QuantegyLabsAccessControl: Admins only');
		_;
	}

	/// @dev Emitted when a new CEO assumes the role
	event CEOUpdated(address newCEO);
	/// @dev Emitted when a new CTO assumes the role
	event CTOUpdated(address newCTO);
	/// @dev Emitted when the contract owner updates the treasury address
	event TreasuryUpdated(address newTreasuryAddress);

	constructor() {
		console.log('Deploying QuantegyLabsAccessControl contract from', msg.sender);
		console.log('CEO and CTO access has been given to', msg.sender);
		// The creator of the contract is the initial CEO
		ceoAddress = msg.sender;
		// The creator of the contract is also the initial CTO
		ctoAddress = msg.sender;
	}

	/// @dev Admin only call to get the CEO address
	function getCEO() public view adminOnly returns (address) {
		return ceoAddress;
	}

	/// @dev Admin only call to get the CTO address
	function getCTO() public view adminOnly returns (address) {
		return ctoAddress;
	}

	/// @dev Admin only call to get the treasury address
	function getTreasury() public view adminOnly returns (address) {
		return treasury;
	}

	/// @dev Assigns a new address to act as the CEO. Only available to the current CEO.
	/// @param _newCEO The address of the new CEO
	function setCEO(address _newCEO) public onlyCEO {
		require(_newCEO != address(0));
		ceoAddress = _newCEO;
		emit CEOUpdated(_newCEO);
	}

	/// @dev Assigns a new address to act as the CTO. Only available to the current CEO.
	/// @param _newCTO The address of the new CTO
	function setCTO(address _newCTO) public adminOnly {
		require(_newCTO != address(0));
		ctoAddress = _newCTO;
		emit CTOUpdated(_newCTO);
	}

	/// @dev Update the treasury address if/when need be
	function setTreasury(address payable _treasury) public onlyCEO {
		treasury = _treasury;
		emit TreasuryUpdated(_treasury);
	}
}