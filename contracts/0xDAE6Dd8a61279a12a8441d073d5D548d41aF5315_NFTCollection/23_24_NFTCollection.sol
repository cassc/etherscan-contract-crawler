// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "erc721a-upgradeable/contracts/ERC721AUpgradeable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "../lib/ERC2981.sol";
import "../lib/Base64.sol";
import "../lib/ITemplate.sol";

/**
 * @title NFTCollection
 * @notice Implements https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension.
 *
 * Uses ERC721A, with token IDs starting from 0 and increasing sequentially.
 * This is a template contract, meaning it cannot be initialized or used directly.
 * The only function of this contract is to store the code that proxies delegate their logic to.
 */
contract NFTCollection is
    ERC721AUpgradeable,
    AccessControlUpgradeable,
    ERC2981,
    ITemplate,
    ReentrancyGuardUpgradeable
{
    using Address for address payable;
    using Strings for uint256;

    /// Fixed at deployment time
    struct DeploymentConfig {
        // Name of the NFT contract.
        string name;
        // Symbol of the NFT contract.
        string symbol;
        // The contract owner address. If you wish to own the contract, then set it as your wallet address.
        // This is also the wallet that can manage the contract on NFT marketplaces. Use `transferOwnership()`
        // to update the contract owner. Owner gets `ADMIN_ROLE` and `DEFAULT_ADMIN_ROLE`, see {AccessControl}.
        // The only part of `DeploymentConfig`, that can be updated after deployment.
        address owner;
        // The maximum number of tokens that can be minted in this collection.
        uint256 maxSupply;
        // The number of free token mints reserved for the contract owner
        uint256 reservedSupply;
        // The maximum number of tokens the user can mint per transaction.
        uint256 tokensPerMint;
        // Treasury address is the address where minting fees can be withdrawn to.
        // Use `withdrawFees()` to transfer the entire contract balance to the treasury address.
        address payable treasuryAddress;
    }

    /// Updatable by admins and owner with `updateConfig`
    struct RuntimeConfig {
        // Metadata base URI for tokens, NFTs minted in this contract will have metadata URI of `baseURI` + `tokenID`.
        // Set this to reveal token metadata.
        string baseURI;
        // If false, the base URI of the NFTs minted in the specified contract can be updated after minting (token URIs
        // are not frozen on the contract level). This is useful for revealing NFTs after the drop. If true, all the
        // NFTs minted in this contract are frozen by default which means token URIs are non-updatable.
        bool metadataFrozen;
        // Minting price per token for public minting
        uint256 publicMintPrice;
        // Flag for freezing the public mint price
        bool publicMintPriceFrozen;
        // Minting price per token for presale minting
        uint256 presaleMintPrice;
        // Flag for freezing the presale mint price
        bool presaleMintPriceFrozen;
        // Starting timestamp for public minting.
        uint256 publicMintStart;
        // Starting timestamp for whitelisted/presale minting,
        // both public and presale minting can be active at the same time.
        uint256 presaleMintStart;
        // Pre-reveal token URI for placeholder metadata. This will be returned for all token IDs until a `baseURI`
        // has been set.
        string prerevealTokenURI;
        // Root of the Merkle tree of whitelisted addresses. This is used to check if a wallet has been whitelisted
        // for presale minting.
        bytes32 presaleMerkleRoot;
        // Secondary market royalties in basis points (100 bps = 1%). Royalties use ERC2981 standard and support
        // OpenSea standard.
        uint256 royaltiesBps;
        // Address for royalties
        address royaltiesAddress;
    }

    // Used in `getInfo()` to get full contract info
    struct ContractInfo {
        // semver-style contract version from `VERSION`
        uint256 version;
        // Contract config that is fixed on deployment
        DeploymentConfig deploymentConfig;
        // Updatable runtime config
        RuntimeConfig runtimeConfig;
    }

    // Event emitted when `transferOwnership` called by current owner.
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /*************
     * Constants *
     *************/

    /// Contract name
    string public constant NAME = "NFTCollection";

    /// Contract version, semver-style uint X_YY_ZZ
    uint256 public constant VERSION = 1_05_00;

    /// Admin role, on contract initialization given to the deployer.
    // Can be updated with `transferOwnership`
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    // Basis for calculating royalties.
    // This has to be 10k for royaltiesBps to be in basis points.
    uint16 public constant ROYALTIES_BASIS = 10000;

    /********************
     * Public variables *
     ********************/

    /// The number of tokens remaining in the reserve
    /// @dev Managed by the contract
    uint256 public reserveRemaining;

    /***************************
     * Contract initialization *
     ***************************/

    constructor() initializer {}

    /// Contract initializer
    // https://eips.ethereum.org/EIPS/eip-1167
    function initialize(
        DeploymentConfig memory deploymentConfig,
        RuntimeConfig memory runtimeConfig
    ) public initializer {
        __ERC721A_init(_deploymentConfig.name, _deploymentConfig.symbol);
        __ReentrancyGuard_init();

        _validateDeploymentConfig(deploymentConfig);
        _validateRuntimeConfig(runtimeConfig);

        // template intializer gets ADMIN_ROLE to call contract write functions
        _grantRole(ADMIN_ROLE, msg.sender);
        // grants `DEFAULT_ADMIN_ROLE` and `ADMIN_ROLE` to `deploymentConfig.owner`
        _transferOwnership(deploymentConfig.owner);

        _deploymentConfig = deploymentConfig;
        _runtimeConfig = runtimeConfig;

        reserveRemaining = deploymentConfig.reservedSupply;
    }

    /****************
     * User actions *
     ****************/

    /// Public mint function, can be called by any address
    /// if `DeploymentConfig.publicMintStart` is before the current block timestamp
    function mint(uint256 amount)
        external
        payable
        paymentProvided(amount * _runtimeConfig.publicMintPrice)
        nonReentrant
    {
        require(mintingActive(), "Minting has not started yet");

        _mintTokens(msg.sender, amount);
    }

    /// Mint tokens if the wallet has been whitelisted, can be called
    /// if `DeploymentConfig.presaleMintStart` is before the current block timestamp
    function presaleMint(uint256 amount, bytes32[] calldata proof)
        external
        payable
        paymentProvided(amount * _runtimeConfig.presaleMintPrice)
        nonReentrant
    {
        require(presaleActive(), "Presale has not started yet");
        require(
            isWhitelisted(msg.sender, proof),
            "Not whitelisted for presale"
        );

        // Each presale whitelisted address can only mint once, up to `DeploymentConfig.tokensPerMint` tokens
        _presaleMinted[msg.sender] = true;
        _mintTokens(msg.sender, amount);
    }

    /******************
     * View functions *
     ******************/

    /// Check if public minting is active
    function mintingActive() public view returns (bool) {
        // We need to rely on block.timestamp since it's
        // easier to configure across different chains
        // solhint-disable-next-line not-rely-on-time
        return block.timestamp > _runtimeConfig.publicMintStart;
    }

    /// Check if presale minting is active
    function presaleActive() public view returns (bool) {
        // We need to rely on block.timestamp since it's
        // easier to configure across different chains
        // solhint-disable-next-line not-rely-on-time
        return block.timestamp > _runtimeConfig.presaleMintStart;
    }

    /// Get the number of tokens still available for minting
    function availableSupply() public view returns (uint256) {
        return _deploymentConfig.maxSupply - totalSupply() - reserveRemaining;
    }

    /// Check if the wallet is whitelisted for the presale
    function isWhitelisted(address wallet, bytes32[] calldata proof)
        public
        view
        returns (bool)
    {
        // Each wallet can only call `presaleMint` once
        require(!_presaleMinted[wallet], "Already minted");

        // Used for checking if wallet is part of the merkle tree
        bytes32 leaf = keccak256(abi.encodePacked(wallet));

        // Checks if `leaf` is part of the merkle tree
        return
            MerkleProof.verify(proof, _runtimeConfig.presaleMerkleRoot, leaf);
    }

    /// Contract owner address
    /// @dev Required for easy integration with OpenSea, the owner address can edit the collection there
    function owner() public view returns (address) {
        return _deploymentConfig.owner;
    }

    /*******************
     * Access controls *
     *******************/

    /// Transfer contract ownership
    function transferOwnership(address newOwner)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(newOwner != _deploymentConfig.owner, "Already the owner");
        _transferOwnership(newOwner);
    }

    /// Transfer contract admin rights, changes `ADMIN_ROLE` from sender address to input `to` address
    /// input `to` address cannot already have `ADMIN_ROLE` access rights
    function transferAdminRights(address to) external onlyRole(ADMIN_ROLE) {
        require(!hasRole(ADMIN_ROLE, to), "Already an admin");
        require(msg.sender != _deploymentConfig.owner, "Use transferOwnership");

        _revokeRole(ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, to);
    }

    /*****************
     * Admin actions *
     *****************/

    /// Mint a token from the reserve
    function reserveMint(address to, uint256 amount)
        external
        onlyRole(ADMIN_ROLE)
    {
        require(amount <= reserveRemaining, "Not enough reserved");
        // if `reserveRemaining` ends up as 0, then further reserve mints are disabled, since `_mintTokens`
        // expects `amount` to be greater than 0
        reserveRemaining -= amount;
        _mintTokens(to, amount);
    }

    /// Get full contract information
    /// @dev Convenience helper
    function getInfo() external view returns (ContractInfo memory info) {
        info.version = VERSION;
        info.deploymentConfig = _deploymentConfig;
        info.runtimeConfig = _runtimeConfig;
    }

    /// Update contract configuration
    /// @dev Callable by admin roles only
    function updateConfig(RuntimeConfig calldata newConfig)
        external
        onlyRole(ADMIN_ROLE)
    {
        _validateRuntimeConfig(newConfig);
        _runtimeConfig = newConfig;
    }

    /// Withdraw minting fees to the treasury address
    /// @dev Callable by admin roles only
    function withdrawFees() external onlyRole(ADMIN_ROLE) {
        _deploymentConfig.treasuryAddress.sendValue(address(this).balance);
    }

    /*************
     * Internals *
     *************/

    /// Contract runtime configuration, updatable after deployment
    RuntimeConfig internal _runtimeConfig;
    /// Contract deployment configuration, immutable after deployment, except for `owner` field
    DeploymentConfig internal _deploymentConfig;

    /// Mapping for tracking presale mint status, each whitelisted address can only presale mint once
    /// up to `DeploymentConfig.tokensPerMint` tokens
    mapping(address => bool) internal _presaleMinted;

    /// @dev Internal function for performing token mints
    function _mintTokens(address to, uint256 amount) internal {
        require(amount <= _deploymentConfig.tokensPerMint, "Amount too large");
        require(amount <= availableSupply(), "Not enough tokens left");

        _safeMint(to, amount);
    }

    /// Validate deployment config
    function _validateDeploymentConfig(DeploymentConfig memory config)
        internal
        pure
    {
        require(config.maxSupply > 0, "Maximum supply must be non-zero");
        require(config.tokensPerMint > 0, "Tokens per mint must be non-zero");
        require(
            config.tokensPerMint <= config.maxSupply,
            "Tokens per mint must be less than max supply"
        );
        require(
            config.treasuryAddress != address(0),
            "Treasury address cannot be null"
        );
        require(config.owner != address(0), "Contract must have an owner");
        require(
            config.reservedSupply <= config.maxSupply,
            "Reserve greater than supply"
        );
    }

    /// Validate a runtime configuration change
    function _validateRuntimeConfig(RuntimeConfig memory config) internal view {
        // Can't set royalties to more than 100%
        require(config.royaltiesBps <= ROYALTIES_BASIS, "Royalties too high");

        // Validate mint price changes
        _validatePropertyChange(
            abi.encodePacked(_runtimeConfig.publicMintPrice),
            _runtimeConfig.publicMintPriceFrozen,
            abi.encodePacked(config.publicMintPrice),
            config.publicMintPriceFrozen
        );

        _validatePropertyChange(
            abi.encodePacked(_runtimeConfig.presaleMintPrice),
            _runtimeConfig.presaleMintPriceFrozen,
            abi.encodePacked(config.presaleMintPrice),
            config.presaleMintPriceFrozen
        );

        // Validate metadata changes
        _validatePropertyChange(
            abi.encodePacked(_runtimeConfig.baseURI),
            _runtimeConfig.metadataFrozen,
            abi.encodePacked(config.baseURI),
            config.metadataFrozen
        );
    }

    /// Validate a change in a variable with a corresponding *Frozen flag.
    /// @dev Variable value is passed in as bytes to generalize across different types.
    function _validatePropertyChange(
        bytes memory prevValue,
        bool prevFrozen,
        bytes memory nextValue,
        bool nextFrozen
    ) internal pure {
        // If the variable wasn't previously frozen, any nextValue and nextFrozen are valid
        if (!prevFrozen) return;
        // Otherwise the variable has to stay frozen
        require(nextFrozen, "Cannot unfreeze variable");
        // And its value is not allowed to change
        require(
            keccak256(prevValue) == keccak256(nextValue),
            "Cannot change frozen variable"
        );
    }

    /// Internal function without any checks for performing the ownership transfer
    /// Removes current `_deploymentConfig.owner` from `ADMIN_ROLE` and `DEFAULT_ADMIN_ROLE` roles and grants these
    /// roles to input `newOwner` address. Changes `_deploymentConfig.owner` to input `newOwner` address
    /// emits an `OwnershipTransferred` event on success
    function _transferOwnership(address newOwner) internal {
        address previousOwner = _deploymentConfig.owner;
        _revokeRole(ADMIN_ROLE, previousOwner);
        _revokeRole(DEFAULT_ADMIN_ROLE, previousOwner);

        _deploymentConfig.owner = newOwner;
        _grantRole(ADMIN_ROLE, newOwner);
        _grantRole(DEFAULT_ADMIN_ROLE, newOwner);

        emit OwnershipTransferred(previousOwner, newOwner);
    }

    /// @dev See {IERC165-supportsInterface}.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721AUpgradeable, AccessControlUpgradeable, ERC2981)
        returns (bool)
    {
        return
            ERC721AUpgradeable.supportsInterface(interfaceId) ||
            AccessControlUpgradeable.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }

    /// Get the token metadata URI
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), "Token does not exist");

        // If `_runtimeConfig.baseURI` is empty then `_runtimeConfig.prerevealTokenURI` is returned
        // otherwise `_runtimeConfig.baseURI` + `tokenId` returned
        return
            bytes(_runtimeConfig.baseURI).length > 0
                ? string(
                    abi.encodePacked(_runtimeConfig.baseURI, tokenId.toString())
                )
                : _runtimeConfig.prerevealTokenURI;
    }

    /// @dev ERC2981 token royalty info
    function royaltyInfo(uint256, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        receiver = _runtimeConfig.royaltiesAddress;
        royaltyAmount =
            (_runtimeConfig.royaltiesBps * salePrice) /
            ROYALTIES_BASIS;
    }

    /**
     * @dev OpenSea contract metadata, returns a base64 encoded JSON string containing royalties basis points
     * and royalties address
     */
    function contractURI() external view returns (string memory) {
        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"seller_fee_basis_points": ', // solhint-disable-line quotes
                        _runtimeConfig.royaltiesBps.toString(),
                        ', "fee_recipient": "', // solhint-disable-line quotes
                        uint256(uint160(_runtimeConfig.royaltiesAddress))
                            .toHexString(20),
                        '"}' // solhint-disable-line quotes
                    )
                )
            )
        );

        string memory output = string(
            abi.encodePacked("data:application/json;base64,", json)
        );

        return output;
    }

    /// Check if enough payment was provided
    modifier paymentProvided(uint256 payment) {
        require(msg.value >= payment, "Payment too small");

        _;

        // If the user overpaid, we refund the excess
        if (msg.value > payment) {
            uint256 excessPayment = msg.value - payment;
            payable(msg.sender).sendValue(excessPayment);
        }
    }
}