// SPDX-License-Identifier: MIT
pragma solidity =0.8.10;

import "./Ownable.sol";

/// @title APUS config contract
/// @notice Holds global variables for the rest of APUS ecosystem
contract Config is Ownable {

	/// @notice Adoption Contribution Rate, where 100% = 10000 = ACR_DECIMAL_PRECISION. 
	/// @dev Percent value where 0 -> 0%, 10 -> 0.1%, 100 -> 1%, 250 -> 2.5%, 550 -> 5.5%, 1000 -> 10%, 0xffff -> 655.35%
	/// @dev Example: x * adoptionContributionRate / ACR_DECIMAL_PRECISION
	uint16 public adoptionContributionRate;

	/// @notice Adoption DAO multisig address
	address payable public adoptionDAOAddress;

	/// @notice Emit when owner changes Adoption Contribution Rate
	/// @param caller Who changed the Adoption Contribution Rate (i.e. who was owner at that moment)
	/// @param previousACR Previous Adoption Contribution Rate
	/// @param newACR New Adoption Contribution Rate
	event ACRChanged(address indexed caller, uint16 previousACR, uint16 newACR);

	/// @notice Emit when owner changes Adoption DAO address
	/// @param caller Who changed the Adoption DAO address (i.e. who was owner at that moment)
	/// @param previousAdoptionDAOAddress Previous Adoption DAO address
	/// @param newAdoptionDAOAddress New Adoption DAO address
	event AdoptionDAOAddressChanged(address indexed caller, address previousAdoptionDAOAddress, address newAdoptionDAOAddress);

	/* solhint-disable-next-line func-visibility */
	constructor(address payable _adoptionDAOAddress, uint16 _initialACR) Ownable(_adoptionDAOAddress) {
		adoptionContributionRate = _initialACR;
		adoptionDAOAddress = _adoptionDAOAddress;
	}


	/// @notice Change Adoption Contribution Rate
	/// @dev Only owner can change Adoption Contribution Rate
	/// @dev Emits `ACRChanged` event
	/// @param _newACR Adoption Contribution Rate
	function setAdoptionContributionRate(uint16 _newACR) external onlyOwner {
		uint16 _previousACR = adoptionContributionRate;
		adoptionContributionRate = _newACR;
		emit ACRChanged(msg.sender, _previousACR, _newACR);
	}

	/// @notice Change Adoption DAO address
	/// @dev Only owner can change Adoption DAO address
	/// @dev Emits `AdoptionDAOAddressChanged` event
	function setAdoptionDAOAddress(address payable _newAdoptionDAOAddress) external onlyOwner {
		address payable _previousAdoptionDAOAddress = adoptionDAOAddress;
		adoptionDAOAddress = _newAdoptionDAOAddress;
		emit AdoptionDAOAddressChanged(msg.sender, _previousAdoptionDAOAddress, _newAdoptionDAOAddress);
	}

}