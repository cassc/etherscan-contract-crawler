// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

/**
 * @dev Interface for ASMBrainGenIIMinter
 */
interface IASMBrainGenIIMinter {
    struct PeriodConfig {
        uint256 startTime;
        uint256 endTime;
        uint256 energyPerBrain;
        uint256 maxSupply;
        uint256 maxQuantityPerTx;
    }

    event ConfigurationUpdated(address indexed operator, uint256 periodId, PeriodConfig config);
    event SignerUpdated(address indexed operator, address signer);
    event ConverterUpdated(address indexed operator, address converter);
    event BrainUpdated(address indexed operator, address _brain);

    error NotStarted();
    error AlreadyFinished();
    error InvalidBrain();
    error InvalidSigner();
    error InvalidMultisig();
    error InvalidConverter();
    error InvalidSignature();
    error InvalidHashes(uint256 length, uint256 max, uint256 min);
    error InsufficientSupply(uint256 quantity, uint256 remaining);
    error InsufficientEnergy(uint256 amount, uint256 remaining);
    error InvalidPeriod(uint256 periodId, uint256 currentPeriodId);

    /**
     * @notice Returns the remaining Gen II Brains supply that can be minted for period `periodId
     * @param periodId The period id to get totalSupply from configuration
     * @return The remaining supply left for the period
     */
    function remainingSupply(uint256 periodId) external view returns (uint256);

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
    ) external;

    /**
     * @notice Update configuration for period `periodId`
     * @dev This function can only to called from contracts or wallets with ADMIN_ROLE
     * @param periodId The periodId to update
     * @param config New config data
     */
    function updateConfiguration(uint256 periodId, PeriodConfig calldata config) external;

    /**
     * @notice Update signer to `signer`
     * @dev This function can only to called from contracts or wallets with ADMIN_ROLE
     * @param signer The new signer address to update
     */
    function updateSigner(address signer) external;

    /**
     * @notice Update converter address to `converter`
     * @dev This function can only to called from contracts or wallets with ADMIN_ROLE
     * @param converter The new converter contract address
     */
    function updateConverter(address converter) external;

    /**
     * @notice Update brain address to `_brain`
     * @dev This function can only to called from contracts or wallets with ADMIN_ROLE
     * @param _brain The new brain contract address
     */
    function updateBrain(address _brain) external;
}