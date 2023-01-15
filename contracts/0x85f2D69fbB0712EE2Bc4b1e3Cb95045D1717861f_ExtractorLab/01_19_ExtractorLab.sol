// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./library/KaijuContracts.sol";

error ExtractorLab__InvalidTokenAmount();
error ExtractorLab__CoolDownOngoing();
error ExtractorLab__SenderNotTokenOwner();
error ExtractorLab__TokenNotStranded();
error ExtractorLab__TokenNotSupported();
error ExtractorLab__Paused();

contract ExtractorLab is IERC721Receiver, IERC1155Receiver, Ownable, ReentrancyGuard, Initializable {
	KaijuContracts.Contracts public contracts;
	uint256 private fee;
	uint256 private extractionCost;
	uint256 private mutantId;
	uint256 private extractedDnaId;
	address private mutantOwner;
	address private lastExtractor;
	bool private paused;

	event Staked(uint256 indexed mutantId, address indexed mutantOwner);
	event Unstaked(uint256 indexed mutantId, address indexed mutantOwner);

	modifier onlyMutantOwner() {
		if (msg.sender != mutantOwner) revert ExtractorLab__SenderNotTokenOwner();
		_;
	}

	function initialize(
		KaijuContracts.Contracts calldata _contracts,
		uint256 _mutantId,
		address owner
	) external initializer {
		contracts = _contracts;
		mutantId = _mutantId;
		extractionCost = 600 ether;
		_transferOwnership(owner);
	}

	/**
	 * @notice Transfers approved Scales/RWaste to contract to run and complete DNA extraction. Mutant owner may still extract when contract is paused
	 */
	function extractDna(uint256 _mutantId, uint16 boostId, uint256 _fee) public nonReentrant {
		if (paused && msg.sender != mutantOwner) revert ExtractorLab__Paused();
		if (contracts.DNA.isCooledDown(_mutantId) != true) revert ExtractorLab__CoolDownOngoing();
		if (_fee != fee) revert ExtractorLab__InvalidTokenAmount();

		uint256 boostCost = contracts.DNA.getBoostCost(boostId);
		IERC20(contracts.RWaste).transferFrom(msg.sender, address(this), boostCost);
		IERC20(contracts.Scales).transferFrom(msg.sender, address(this), extractionCost + _fee);
		contracts.Scales.deposit(extractionCost);

		contracts.DNA.runExtraction(_mutantId, boostId);
		contracts.DNA.completeExtraction(_mutantId);
		lastExtractor = msg.sender;
	}

	function transferDna() public {
		int256 dnaId = getExtractedDnaId();
		if (lastExtractor != msg.sender) revert ExtractorLab__SenderNotTokenOwner();
		if (dnaId < 0) revert ExtractorLab__InvalidTokenAmount();
		lastExtractor = address(0);
		extractedDnaId = 0;
		contracts.DNA.safeTransferFrom(address(this), msg.sender, uint256(dnaId), 1, "");
	}

	function getMutantId() public view returns (uint256) {
		return mutantId;
	}

	function getMutantOwner() public view returns (address) {
		return mutantOwner;
	}

	function setFee(uint256 _fee) public onlyMutantOwner {
		fee = _fee;
	}

	function getFee() public view returns (uint256) {
		return fee;
	}

	function setExtractionCost() public {
		extractionCost = contracts.DNA.extractionCost();
	}

	function getTotalExtractionCost() public view returns (uint256) {
		return extractionCost + fee;
	}

	function getLastExtractor() public view returns (address) {
		return lastExtractor;
	}

	/**
	 * @notice returns value for extractedDnaId or -1 if no DNA is available. extractedDnaId is set to 0 for the cheaper SSTORE when
	 * resetting variable after transfer but causes overlap with DNA id: 0
	 */
	function getExtractedDnaId() public view returns (int256) {
		return int256(extractedDnaId) - 1;
	}

	function withdraw(uint256 scales) public onlyMutantOwner {
		contracts.Scales.transfer(msg.sender, scales);
	}

	/**
	 * @notice used for recovery of mutants that were accidentally transfered to contract.
	 * Cannot be used to transfer staked mutant
	 */
	function recoveryTransferMutant(address to, uint256 tokenId) external onlyOwner {
		if (tokenId == mutantId && mutantOwner != address(0)) revert ExtractorLab__TokenNotStranded();
		contracts.Mutant.transferFrom(address(this), to, tokenId);
	}

	function stakeMutant(uint256 _mutantId) public {
		if (contracts.Mutant.ownerOf(_mutantId) != msg.sender) revert ExtractorLab__SenderNotTokenOwner();
		if (mutantOwner != msg.sender) {
			mutantOwner = msg.sender;
		}
		contracts.Mutant.safeTransferFrom(msg.sender, address(this), _mutantId);
		emit Staked(_mutantId, msg.sender);
	}

	function unstakeMutant(uint256 _mutantId) public onlyMutantOwner {
		mutantOwner = address(0);
		paused = false;
		contracts.Mutant.safeTransferFrom(address(this), msg.sender, _mutantId);
		emit Unstaked(_mutantId, msg.sender);
	}

	/**
	 * @notice Pause/unpause the ability to extract for users. This does not affect the mutant owner's ability to perform extractions
	 */
	function togglePauseState() public onlyMutantOwner {
		paused = !paused;
	}

	function getPauseState() public view returns (bool) {
		return paused;
	}

	function onERC721Received(
		address,
		address,
		uint256 tokenId,
		bytes calldata
	) external view override returns (bytes4) {
		if (msg.sender != address(contracts.Mutant) || tokenId != mutantId) revert ExtractorLab__TokenNotSupported();
		return this.onERC721Received.selector;
	}

	function supportsInterface(bytes4 interfaceId) external view override returns (bool) {}

	function onERC1155Received(
		address,
		address,
		uint256 id,
		uint256,
		bytes calldata
	) external override returns (bytes4) {
		if (msg.sender == address(contracts.DNA)) {
			extractedDnaId = id + 1; // increment to prevent overlap with dna id: 0 when resetting extractedDnaId to 0
		} else {
			revert ExtractorLab__TokenNotSupported();
		}
		return this.onERC1155Received.selector;
	}

	function onERC1155BatchReceived(
		address,
		address,
		uint256[] calldata,
		uint256[] calldata,
		bytes calldata
	) external pure override returns (bytes4) {
		revert ExtractorLab__TokenNotSupported();
	}
}