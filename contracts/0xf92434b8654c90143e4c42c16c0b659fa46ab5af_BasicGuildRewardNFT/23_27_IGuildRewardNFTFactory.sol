// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title A simple factory deploying minimal proxy contracts for Guild reward NFTs.
interface IGuildRewardNFTFactory {
    /// @notice The type of the contract.
    /// @dev Used as an identifier. Should be expanded in future updates.
    enum ContractType {
        BASIC_NFT
    }

    /// @notice Information about a specific deployment.
    /// @param contractAddress The address where the contract/clone is deployed.
    /// @param contractType The type of the contract.
    struct Deployment {
        address contractAddress;
        ContractType contractType;
    }

    /// @return signer The address that signs the metadata.
    function validSigner() external view returns (address signer);

    /// @notice Maps deployed implementation contract addresses to contract types.
    /// @param contractType The type of the contract.
    /// @return contractAddress The address of the deployed NFT contract.
    function nftImplementations(ContractType contractType) external view returns (address contractAddress);

    /// @notice Sets the associated addresses.
    /// @dev Initializer function callable only once.
    /// @param treasuryAddress The address that will receive the fees.
    /// @param fee The Guild base fee for every deployment.
    /// @param validSignerAddress The address that will sign the metadata.
    function initialize(address payable treasuryAddress, uint256 fee, address validSignerAddress) external;

    /// @notice Deploys a minimal proxy for a basic NFT.
    /// @param name The name of the NFT to be created.
    /// @param symbol The symbol of the NFT to be created.
    /// @param cid The cid used to construct the tokenURI of the NFT to be created.
    /// @param tokenOwner The address that will be the owner of the deployed token.
    /// @param tokenTreasury The address that will collect the prices of the minted deployed tokens.
    /// @param tokenFee The price of every mint in wei.
    function deployBasicNFT(
        string calldata name,
        string calldata symbol,
        string calldata cid,
        address tokenOwner,
        address payable tokenTreasury,
        uint256 tokenFee
    ) external;

    /// @notice Returns the reward NFT addresses for a guild.
    /// @param deployer The address that deployed the tokens.
    /// @return tokens The addresses of the tokens deployed by deployer.
    function getDeployedTokenContracts(address deployer) external view returns (Deployment[] memory tokens);

    /// @notice Sets the address that signs the metadata.
    /// @dev Callable only by the owner.
    /// @param newValidSigner The new address of validSigner.
    function setValidSigner(address newValidSigner) external;

    /// @notice Sets the address of the contract where a specific NFT is implemented.
    /// @dev Callable only by the owner.
    /// @param contractType The type of the contract.
    /// @param newNFT The address of the deployed NFT contract.
    function setNFTImplementation(ContractType contractType, address newNFT) external;

    /// @notice Event emitted when an NFT implementation is changed.
    /// @param contractType The type of the contract.
    /// @param newNFT The new address of the NFT implementation.
    event ImplementationChanged(ContractType contractType, address newNFT);

    /// @notice Event emitted when a new NFT is deployed.
    /// @param deployer The address that deployed the token.
    /// @param tokenAddress The address of the token.
    event RewardNFTDeployed(address deployer, address tokenAddress);

    /// @notice Event emitted when the validSigner is changed.
    /// @param newValidSigner The new address of validSigner.
    event ValidSignerChanged(address newValidSigner);
}