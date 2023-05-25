// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

/// @dev We can pas salt in to create deterministic address in solidity
// https://docs.soliditylang.org/en/develop/control-structures.html#salted-contract-creations-create2
// Reference: https://github.com/Uniswap/v3-core/blob/main/contracts/UniswapV3Factory.sol
// Reference: https://github.com/Uniswap/v3-core/blob/main/contracts/UniswapV3PoolDeployer.sol


/// @title Interface for StakefishValidatorFactory
/// @notice The interface for validator factory responsible for deploying validator address.
/// There's no need chain dependency against NFTManager which adds complexity. Instead NFTManager
/// can define which factory it trusts to deploy its validators.
interface IStakefishValidatorFactory {
    /// @notice Create validator contract with ETH deposits
    /// @param tokenId The number of validators
    function createValidator(uint256 tokenId) external payable returns (address);

    /// @notice computes the validator contract address
    /// @param tokenId Computes based on tokenId
    function computeAddress(address deployer, uint256 tokenId) external view returns (address);

    /// @notice sets operator address
    function setOperator(address operator) external;

    /// @notice sets owner who can set the fees
    function setDeployer(address deployer, bool enabled) external;

    /// @notice sets the protocol fee
    /// @param feePercent is the fee percent in basis points eg. 1% = 100
    function setFee(uint256 feePercent) external;

    /// @notice sets the rate by minter
    /// @param minter is the address of NFT minter
    /// @param feePercent is the fee percent in basis points eg. 1% = 100
    function setFeeForMinter(address minter, uint256 feePercent) external;

    /// @notice sets migration address
    function setMigrationAddress(address _migrationAddress) external;

    /// @notice sets the max number of validators that can be created per transaction
    /// @param maxCount the new max number of validators per transaction
    function setMaxValidatorsPerTransaction(uint256 maxCount) external;

    /// @notice sets the server url for NFT metadata
    function setNFTArtUrl(string calldata _nftURL) external;

    /// @notice returns latest version contract
    function addVersion(address implementation) external;

    /// @notice returns implementation at index
    function implementations(uint256 index) external view returns (address);

    /// @notice returns latest version contract
    function latestVersion() external view returns (address);

    /// @notice returns operator address (which can be a contract or EOA)
    function operatorAddress() external view returns (address);

    /// @notice returns migration nft manager address
    function migrationAddress() external view returns (address);

    /// @notice returns protocol fee
    function protocolFee() external view returns (uint256);

    /// @notice returns protocol fee by minter
    function getProtocolFeeForMinter(address minter) external view returns (uint256);

    /// @notice returns max number of validators that can be created per transaction
    function maxValidatorsPerTransaction() external view returns (uint256);

    /// @notice returns server URL
    function nftArtURL() external view returns (string memory);

    /// @notice withdraw commission
    function withdraw() external;
}