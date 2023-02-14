// SPDX-License-Identifier: MIT
  
pragma solidity ^0.8.0;

import "./presets/ERC721EnviousDynamicPreset.sol";

contract GhostCollection is ERC721EnviousDynamicPreset {
	
	address private _superUser;
	address private _superMinter;
	
	constructor(
		string memory tokenName,
		string memory tokenSymbol,
		string memory baseTokenURI,
		uint256[] memory edgeValues,
		uint256[] memory edgeOffsets,
		uint256[] memory edgeRanges,
		address tokenMeasurment
	) ERC721EnviousDynamicPreset(
		tokenName,
		tokenSymbol,
		baseTokenURI,
		edgeValues,
		edgeOffsets,
		edgeRanges,
		tokenMeasurment
	) {
		_superUser = _msgSender();
		_superMinter = _msgSender();
	}

	modifier onlySuperUser {
		require(_msgSender() == _superUser, "only for super user");
		_;
	}

	function mint(address to) public override {
		require(_msgSender() == _superMinter, "only for super minter");
		super.mint(to);
	}

	function setGhostAddresses(
		address ghostToken, 
		address ghostBonding
	) public override onlySuperUser {
		super.setGhostAddresses(ghostToken, ghostBonding);
	}

	function changeBaseUri(string memory newBaseURI) external onlySuperUser {
		super._changeBaseURI(newBaseURI);
	}

	function renewSuperMinter(address who) external onlySuperUser {
		_superMinter = who;
	}
}