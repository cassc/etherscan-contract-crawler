// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./erc721A/ERC721A.sol";
import "./Manageable.sol";

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

error Neutron__NoSaleStageActive();

error Neutron__InvalidConfiguration();
error Neutron__InvalidSaleStageIndex();
error Neutron__InvalidInput();

error Neutron__WrongEtherAmmount();
error Neutron__ExceedingMaxSupply();
error Neutron__ExceedingTokensPerStageLimit();

error Neutron__HashComparisonFailed();
error Neutron__UntrustedSigner();
error Neutron__SignatureAlreadyUsed();

/**
 * @dev Configuration of a sale stage.
 *
 * @param startTime The start time of the sale stage.
 * @param endTime The end time of the sale stage.
 * @param supplyLimitByTheEndOfStage The maximum number of tokens that can be minted by the end of the sale stage.
 * @param maxTokensPerWallet The maximum number of tokens that can be minted by a single wallet during the sale stage.
 * @param weiTokenPrice The price of a token in wei.
 */
struct SaleStageConfig {
	uint32 startTime;
	uint32 endTime;
	uint16 supplyLimitByTheEndOfStage;
	uint16 maxTokensPerWallet;
	uint256 weiTokenPrice;
}

/**
 * @dev A signature package, that secures the minting of tokens.
 *
 * @param messageHash The hash of the minting operation message.
 * @param signature The signature for the message hash.
 * @param nonce The nonce, that is used to prevent replay attacks.
 */
struct SaleSignaturePackage {
	bytes32 messageHash;
	bytes signature;
	uint64 nonce;
}

/**
 * @title Neutron
 * @author DeployLabs.io
 *
 * @dev Neutron is a contract for managing a token collection.
 * Version 1.1.0
 */
abstract contract Neutron is ERC721A, Manageable {
	bytes8 private immutable i_hashSalt;
	address private immutable i_signerAddress;

	string private s_baseTokenUri;

	uint16[] internal s_saleStageIds;
	uint16 internal s_lastAssignedStageId = 0;

	mapping(uint16 => SaleStageConfig) internal s_saleStageConfigurations;
	mapping(uint16 => mapping(address => uint256)) internal s_numberMintedDuringStage;

	mapping(uint64 => bool) internal s_usedNonces;

	constructor(
		string memory name,
		string memory symbol,
		bytes8 hashSalt,
		address signerAddress
	) ERC721A(name, symbol) {
		i_hashSalt = hashSalt;
		i_signerAddress = signerAddress;
	}

	/**
	 * @dev Mint a token to the caller.
	 *
	 * @param signaturePackage The signature package for security.
	 * @param quantity The quantity of tokens to mint.
	 */
	function mint(
		SaleSignaturePackage calldata signaturePackage,
		uint256 quantity
	) external payable {
		uint16 currentStageIndex = getCurrentSaleStageIndex();
		uint16 currentStageId = s_saleStageIds[currentStageIndex];
		SaleStageConfig memory config = getSaleStageConfig(currentStageIndex);

		if (msg.value != config.weiTokenPrice * quantity) revert Neutron__WrongEtherAmmount();
		if (totalSupply() + quantity > config.supplyLimitByTheEndOfStage)
			revert Neutron__ExceedingMaxSupply();
		if (
			s_numberMintedDuringStage[currentStageId][msg.sender] + quantity >
			config.maxTokensPerWallet
		) revert Neutron__ExceedingTokensPerStageLimit();

		if (!_isCorrectMintOperationHash(signaturePackage, msg.sender, quantity))
			revert Neutron__HashComparisonFailed();
		if (!_isTrustedSigner(signaturePackage.messageHash, signaturePackage.signature))
			revert Neutron__UntrustedSigner();
		if (s_usedNonces[signaturePackage.nonce]) revert Neutron__SignatureAlreadyUsed();

		s_numberMintedDuringStage[currentStageId][msg.sender] += quantity;
		s_usedNonces[signaturePackage.nonce] = true;

		_safeMint(msg.sender, quantity);
	}

	/**
	 * @dev Airdrop tokens to a list of recipients.
	 *
	 * @param airdropTo The list of recipients.
	 * @param quantity The list of quantities.
	 */
	function airdrop(
		address[] calldata airdropTo,
		uint256[] calldata quantity
	) external onlyManager {
		if (airdropTo.length != quantity.length) revert Neutron__InvalidInput();

		for (uint256 i = 0; i < airdropTo.length; i++) {
			_safeMint(airdropTo[i], quantity[i]);
		}
	}

	/**
	 * @dev Add a new sale stage. The sale stage must be added in chronological order.
	 *
	 * @param config The configuration of the sale stage.
	 */
	function addSaleStage(SaleStageConfig calldata config) external onlyManager {
		if (config.startTime >= config.endTime) revert Neutron__InvalidConfiguration();
		if (config.supplyLimitByTheEndOfStage == 0) revert Neutron__InvalidConfiguration();
		if (config.maxTokensPerWallet == 0) revert Neutron__InvalidConfiguration();

		s_lastAssignedStageId += 1;
		s_saleStageIds.push(s_lastAssignedStageId);
		s_saleStageConfigurations[s_lastAssignedStageId] = config;
	}

	/**
	 * @dev Remove a sale stage.
	 *
	 * @param stageIndex The index of the sale stage to remove.
	 */
	function removeSaleStage(uint16 stageIndex) external onlyManager {
		if (stageIndex >= s_saleStageIds.length) revert Neutron__InvalidSaleStageIndex();

		for (uint256 i = stageIndex; i < s_saleStageIds.length - 1; i++) {
			s_saleStageIds[i] = s_saleStageIds[i + 1];
		}

		s_saleStageIds.pop();
	}

	/**
	 * @dev Edit an existing sale stage.
	 *
	 * @param stageIndex The index of the sale stage to edit.
	 * @param config The new configuration of the sale stage.
	 */
	function editSaleStage(
		uint16 stageIndex,
		SaleStageConfig calldata config
	) external onlyManager {
		if (stageIndex >= s_saleStageIds.length) revert Neutron__InvalidSaleStageIndex();
		if (config.startTime >= config.endTime) revert Neutron__InvalidConfiguration();
		if (config.supplyLimitByTheEndOfStage == 0) revert Neutron__InvalidConfiguration();
		if (config.maxTokensPerWallet == 0) revert Neutron__InvalidConfiguration();

		s_saleStageConfigurations[s_saleStageIds[stageIndex]] = config;
	}

	/**
	 * @dev Reset a sale stage. This will increment the stage ID, which will invalidate all previous linked operations.
	 *
	 * @param stageIndex The index of the sale stage to reset.
	 */
	function resetSaleStage(uint16 stageIndex) external onlyManager {
		if (stageIndex >= s_saleStageIds.length) revert Neutron__InvalidSaleStageIndex();

		s_lastAssignedStageId += 1;
		s_saleStageIds[stageIndex] = s_lastAssignedStageId;
	}

	/**
	 * @dev Set base URI for token metadata.
	 *
	 * @param baseUri The base URI for token metadata.
	 */
	function setBaseUri(string calldata baseUri) external onlyManager {
		s_baseTokenUri = baseUri;
	}

	/**
	 * @dev Get the number of sale stages.
	 *
	 * @return saleStagesCount The number of sale stages in the contract.
	 */
	function getSaleStagesCount() external view returns (uint256 saleStagesCount) {
		saleStagesCount = s_saleStageIds.length;
	}

	/**
	 * @dev Get the number of tokens minted during a sale stage.
	 *
	 * @param stageIndex The index of the sale stage.
	 * @param wallet The wallet to get the count for.
	 *
	 * @return countMintedDuringStage The number of tokens minted during the sale stage.
	 */
	function getMintedCountDuringSaleStage(
		uint16 stageIndex,
		address wallet
	) external view returns (uint256 countMintedDuringStage) {
		if (stageIndex >= s_saleStageIds.length) revert Neutron__InvalidSaleStageIndex();

		countMintedDuringStage = s_numberMintedDuringStage[s_saleStageIds[stageIndex]][wallet];
	}

	/**
	 * @dev Get the sale stage configuration.
	 *
	 * @param stageIndex The index of the sale stage.
	 *
	 * @return config The sale stage configuration.
	 */
	function getSaleStageConfig(
		uint16 stageIndex
	) public view returns (SaleStageConfig memory config) {
		if (stageIndex >= s_saleStageIds.length) revert Neutron__InvalidSaleStageIndex();

		config = s_saleStageConfigurations[s_saleStageIds[stageIndex]];
	}

	/**
	 * @dev Get the current sale stage index.
	 *
	 * @return currentStageIndex The current sale stage index.
	 */
	function getCurrentSaleStageIndex() public view returns (uint16 currentStageIndex) {
		uint256 currentTimestamp = block.timestamp;
		uint16[] memory saleStageIds = s_saleStageIds;

		for (; currentStageIndex < saleStageIds.length; currentStageIndex++) {
			SaleStageConfig memory config = s_saleStageConfigurations[
				saleStageIds[currentStageIndex]
			];

			if (currentTimestamp >= config.startTime && currentTimestamp < config.endTime) {
				return currentStageIndex;
			}
		}

		revert Neutron__NoSaleStageActive();
	}

	/**
	 * @dev Get data used to generate the signature.
	 *
	 * @return hashSalt The hash salt.
	 * @return signerAddress The signer address.
	 */
	function getSignatureData() public view returns (bytes8 hashSalt, address signerAddress) {
		return (i_hashSalt, i_signerAddress);
	}

	/**
	 * @dev Starting ID for the tokens.
	 *
	 * @return The starting ID for the tokens.
	 */
	function _startTokenId() internal view virtual override returns (uint256) {
		return 1;
	}

	/**
	 * @dev Get base token URI.
	 *
	 * @return The base token URI.
	 */
	function _baseURI() internal view virtual override returns (string memory) {
		return s_baseTokenUri;
	}

	/**
	 * @dev Check whether a message hash is the one that has been signed.
	 *
	 * @param signaturePackage The signature package.
	 * @param mintTo The address of the minter.
	 * @param quantity The quantity of tokens to mint.
	 *
	 * @return isCorrectMintOperationHash Whether the message hash matches the one that has been signed.
	 */
	function _isCorrectMintOperationHash(
		SaleSignaturePackage calldata signaturePackage,
		address mintTo,
		uint256 quantity
	) internal view returns (bool isCorrectMintOperationHash) {
		uint16 currentSaleStageIndex = getCurrentSaleStageIndex();

		bytes memory message = abi.encodePacked(
			i_hashSalt,
			mintTo,
			uint64(block.chainid),
			currentSaleStageIndex,
			uint64(quantity),
			signaturePackage.nonce
		);
		bytes32 messageHash = keccak256(message);

		isCorrectMintOperationHash = messageHash == signaturePackage.messageHash;
	}

	/**
	 * @dev Check whether a message hash was signed by a trusted address.
	 *
	 * @param messageHash The hash of the opertaion message.
	 * @param signature The signature for the message hash.
	 *
	 * @return isTrustedSigner Whether the message was signed by a trusted address.
	 */
	function _isTrustedSigner(
		bytes32 messageHash,
		bytes memory signature
	) internal view returns (bool isTrustedSigner) {
		isTrustedSigner = i_signerAddress == ECDSA.recover(messageHash, signature);
	}
}