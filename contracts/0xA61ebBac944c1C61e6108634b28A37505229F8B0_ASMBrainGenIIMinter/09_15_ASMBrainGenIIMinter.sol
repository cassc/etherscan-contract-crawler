// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/IConverterLogic.sol";
import "./interfaces/IASMBrainGenII.sol";
import "./interfaces/IASMBrainGenIIMinter.sol";
import "./helpers/Util.sol";

contract ASMBrainGenIIMinter is IASMBrainGenIIMinter, Util, AccessControl, ReentrancyGuard {
    using ECDSA for bytes32;

    address private _signer;

    IConverterLogic public energyConverter;
    IASMBrainGenII public brain;

    // PeriodId => config
    mapping(uint256 => PeriodConfig) public configuration;

    constructor(
        address signer,
        address _multisig,
        address _converter,
        address _brain
    ) {
        if (signer == address(0)) revert InvalidSigner();
        if (_multisig == address(0)) revert InvalidMultisig();
        if (_converter == address(0)) revert InvalidConverter();
        if (_brain == address(0)) revert InvalidBrain();

        _signer = signer;
        _grantRole(ADMIN_ROLE, _multisig);

        energyConverter = IConverterLogic(_converter);
        brain = IASMBrainGenII(_brain);
    }

    /**
     * @notice Encode arguments to generate a hash, which will be used for validating signatures
     * @dev This function can only be called inside the contract
     * @param hashes A list of IPFS Multihash digests. Each Gen II Brain should have an unique token hash
     * @param recipient The user wallet address, to verify the signature can only be used by the wallet
     * @param numberMinted The total minted Gen II Brains amount from the user wallet address
     * @return Encoded hash
     */
    function _hash(
        bytes32[] calldata hashes,
        address recipient,
        uint256 numberMinted
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(hashes, recipient, numberMinted));
    }

    /**
     * @notice To verify the `token` is signed by the _signer
     * @dev This function can only be called inside the contract
     * @param hash The encoded hash used for signature
     * @param token The signature passed from the caller
     * @return Verification result
     */
    function _verify(bytes32 hash, bytes memory token) internal view returns (bool) {
        return (_recover(hash, token) == _signer);
    }

    /**
     * @notice Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     * @dev This function can only be called inside the contract
     * @param hash The encoded hash used for signature
     * @param token The signature passed from the caller
     * @return The recovered address
     */
    function _recover(bytes32 hash, bytes memory token) internal pure returns (address) {
        return hash.toEthSignedMessageHash().recover(token);
    }

    /**
     * @notice To validate the `signature` is signed by the _signer
     * @param hashes The bytes32 hash list for signature
     * @param addr User wallet address
     * @param signature The signature passed from the caller
     * @return Validation result
     */
    function validateSignature(
        bytes32[] calldata hashes,
        address addr,
        uint256 numberMinted,
        bytes calldata signature
    ) public view returns (bool) {
        return _verify(_hash(hashes, addr, numberMinted), signature);
    }

    /**
     * @notice Consume ASTO Energy to mint Gen II Brains with the IPFS hashes
     * @param hashes A list of IPFS Multihash digests. Each Gen II Brain should have an unique token hash
     * @param signature The signature for verification. It should be generated from the Dapp and can only be used once
     * @param periodId Used to get the remaining ASTO Energy for the user
     */
    function mint(
        bytes32[] calldata hashes,
        bytes calldata signature,
        uint256 periodId
    ) external nonReentrant {
        uint256 quantity = hashes.length;
        if (quantity > remainingSupply(periodId)) revert InsufficientSupply(quantity, remainingSupply(periodId));
        PeriodConfig memory config = configuration[periodId];
        if (quantity == 0) revert InvalidHashes(quantity, config.maxQuantityPerTx, 1);
        if (quantity > config.maxQuantityPerTx) revert InvalidHashes(quantity, config.maxQuantityPerTx, 1);

        // solhint-disable-next-line not-rely-on-time
        if (block.timestamp < config.startTime) revert NotStarted();
        // solhint-disable-next-line not-rely-on-time
        if (block.timestamp >= config.endTime) revert AlreadyFinished();

        // Only allow use enery accumulated from previous production cycles. Please refer to the following link for details
        // https://github.com/altered-state-machine/genome-mining-contracts/blob/main/audit/requirements.md#business-requirements
        if (periodId + 1 > energyConverter.getCurrentPeriodId())
            revert InvalidPeriod(periodId, energyConverter.getCurrentPeriodId());

        if (!validateSignature(hashes, msg.sender, brain.numberMinted(msg.sender), signature))
            revert InvalidSignature();

        uint256 remainingEnergy = energyConverter.getEnergy(msg.sender, periodId);
        uint256 energyToUse = quantity * config.energyPerBrain;
        if (energyToUse > remainingEnergy) revert InsufficientEnergy(energyToUse, remainingEnergy);
        energyConverter.useEnergy(msg.sender, periodId, energyToUse);

        brain.mint(msg.sender, hashes);
    }

    /**
     * @notice Returns the remaining Gen II Brains supply that can be minted for period `periodId
     * @param periodId The period id to get totalSupply from configuration
     * @return The remaining supply left for the period
     */
    function remainingSupply(uint256 periodId) public view returns (uint256) {
        PeriodConfig memory config = configuration[periodId];
        return config.maxSupply > brain.totalSupply() ? config.maxSupply - brain.totalSupply() : 0;
    }

    /**
     * @notice Update configuration for period `periodId`
     * @dev This function can only to called from contracts or wallets with ADMIN_ROLE
     * @param periodId The periodId to update
     * @param config New config data
     */
    function updateConfiguration(uint256 periodId, PeriodConfig calldata config) external onlyRole(ADMIN_ROLE) {
        configuration[periodId] = config;
        emit ConfigurationUpdated(msg.sender, periodId, config);
    }

    /**
     * @notice Update signer to `signer`
     * @dev This function can only to called from contracts or wallets with ADMIN_ROLE
     * @param signer The new signer address to update
     */
    function updateSigner(address signer) external onlyRole(ADMIN_ROLE) {
        if (signer == address(0)) revert InvalidSigner();
        _signer = signer;
        emit SignerUpdated(msg.sender, signer);
    }

    /**
     * @notice Update converter address to `converter`
     * @dev This function can only to called from contracts or wallets with ADMIN_ROLE
     * @param converter The new converter contract address
     */
    function updateConverter(address converter) external onlyRole(ADMIN_ROLE) {
        if (converter == address(0)) revert InvalidConverter();
        energyConverter = IConverterLogic(converter);
        emit ConverterUpdated(msg.sender, converter);
    }

    /**
     * @notice Update brain address to `_brain`
     * @dev This function can only to called from contracts or wallets with ADMIN_ROLE
     * @param _brain The new brain contract address
     */
    function updateBrain(address _brain) external onlyRole(ADMIN_ROLE) {
        if (_brain == address(0)) revert InvalidBrain();
        brain = IASMBrainGenII(_brain);
        emit BrainUpdated(msg.sender, _brain);
    }
}