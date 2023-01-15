// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./library/KaijuContracts.sol";
import "../interfaces/IMutants.sol";
import "../interfaces/IExtractorLab.sol";
import "../interfaces/IDNA.sol";
import "../interfaces/IScales.sol";
import "../interfaces/IRWaste.sol";

error ExtractorLabFactory__SenderNotTokenOwner();
error ExtractorLabFactory__CloneExists();

contract ExtractorLabFactory is Ownable {
	KaijuContracts.Contracts public contracts;
	address public extractorLabAddress;
	IExtractorLab public ExtractorLab;
	mapping(uint256 => address) public mutantToLab;
	uint256[] public mutantIds;

	event LabCreated(uint256 indexed mutantId, address indexed contractAddress);

	constructor(
		address _extractorLabAddress,
		address dnaAddress,
		address rwasteAddress,
		address scalesAddress,
		address mutantAddress
	) {
		extractorLabAddress = _extractorLabAddress;
		contracts.DNA = IDNA(dnaAddress);
		contracts.RWaste = IRWaste(rwasteAddress);
		contracts.Scales = IScales(scalesAddress);
		contracts.Mutant = IMutants(mutantAddress);
		ExtractorLab = IExtractorLab(extractorLabAddress);
	}

	function createLab(uint256 mutantId) public {
		if (msg.sender != contracts.Mutant.ownerOf(mutantId)) revert ExtractorLabFactory__SenderNotTokenOwner();
		if (address(mutantToLab[mutantId]) != address(0)) revert ExtractorLabFactory__CloneExists();
		address labAddress = Clones.clone(extractorLabAddress);
		IExtractorLab.Contracts memory initContracts = IExtractorLab.Contracts(
			contracts.DNA,
			contracts.RWaste,
			contracts.Scales,
			contracts.Mutant
		);
		IExtractorLab(labAddress).initialize(initContracts, mutantId, owner());
		mutantToLab[mutantId] = labAddress;
		mutantIds.push(mutantId);
		emit LabCreated(mutantId, labAddress);
	}

	function getMutantIds() public view returns (uint256[] memory) {
		return mutantIds;
	}
}