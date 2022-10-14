// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import "./ERC2981.sol";
import "./Base64.sol";

contract NFTCollection is ERC721, ERC2981, AccessControl, Initializable {
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
        // to update the contract owner.
        address owner;
        // The fee address of JustMint.org
        address providerAddress;
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

    /// Updatable by admins and owner
    struct RuntimeConfig {
        // Metadata base URI for tokens, NFTs minted in this contract will have metadata URI of `baseURI` + `tokenID`.
        // Set this to reveal token metadata.
        string baseURI;
        // If true, the base URI of the NFTs minted in the specified contract can be updated after minting (token URIs
        // are not frozen on the contract level). This is useful for revealing NFTs after the drop. If false, all the
        // NFTs minted in this contract are frozen by default which means token URIs are non-updatable.
        bool metadataUpdatable;
        // Starting timestamp for public minting.
        uint256 publicMintStart;
        // Starting timestamp for whitelisted/presale minting.
        uint256 presaleMintStart;
        // Pre-reveal token URI for placholder metadata. This will be returned for all token IDs until a `baseURI`
        // has been set.
        string prerevealTokenURI;
        // Root of the Merkle tree of whitelisted addresses. This is used to check if a wallet has been whitelisted
        // for presale minting.
        bytes32 presaleMerkleRoot;
        // Secondary market royalties in basis points (100 bps = 1%)
        uint256 royaltiesBps;
        // Address for royalties
        address royaltiesAddress;
        // Minting price per token.
        uint256 mintPrice;
    }

    struct ContractInfo {
        uint256 version;
        DeploymentConfig deploymentConfig;
        RuntimeConfig runtimeConfig;
    }

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /*************
     * Constants *
     *************/

    /// Contract version, semver-style uint X_YY_ZZ
    uint256 public constant VERSION = 1_02_00;

    /// Admin role
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    // Basis for calculating royalties.
    // This has to be 10k for royaltiesBps to be in basis points.
    uint16 constant ROYALTIES_BASIS = 10000;

    /********************
     * Public variables *
     ********************/

    /// The number of currently minted tokens
    /// @dev Managed by the contract
    uint256 public totalSupply;

    /***************************
     * Contract initialization *
     ***************************/

    constructor() ERC721("", "") {
        _preventInitialization = true;
    }

    /// Contract initializer
    function initialize(
        DeploymentConfig memory deploymentConfig,
        RuntimeConfig memory runtimeConfig
    ) public initializer {
        require(!_preventInitialization, "Cannot be initialized");
        _validateDeploymentConfig(deploymentConfig);

        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, deploymentConfig.owner);
        _grantRole(DEFAULT_ADMIN_ROLE, deploymentConfig.owner);

        _deploymentConfig = deploymentConfig;
        _runtimeConfig = runtimeConfig;
    }

    /****************
     * User actions *
     ****************/

    function creditCardMint(address to, uint256 amount) external payable paymentProvided(amount) {
        /// CrossMint currently only for public sales
        require(mintingActive(), "Minting has not started yet");
        require(msg.sender == 0xdAb1a1854214684acE522439684a145E62505233,
            "This function is reserved for credit-card payments."
        );
        _mintTokens(to, amount);
    }

    /// Mint tokens1
    function mint(uint256 amount) external payable paymentProvided(amount) {
        require(mintingActive(), "Minting has not started yet");
        _mintTokens(msg.sender, amount);
    }

    /// Mint tokens if the wallet has been whitelisted
    function presaleMint(uint256 amount, bytes32[] calldata proof)
    external
    payable
    paymentProvided(amount)
    {
        require(presaleActive(), "Presale has not started yet");
        require(
            isWhitelisted(msg.sender, proof),
            "Not whitelisted for presale"
        );

        _presaleMinted[msg.sender] = true;
        _mintTokens(msg.sender, amount);
    }

    /******************
     * View functions *
     ******************/
    /// Check if public minting is active
    function mintingActive() public view returns (bool) {
        return block.timestamp > _runtimeConfig.publicMintStart;
    }

    /// Check if presale minting is active
    function presaleActive() public view returns (bool) {
        return block.timestamp > _runtimeConfig.presaleMintStart;
    }

    /// Get the number of tokens still available for minting
    function availableSupply() public view returns (uint256) {
        return
        _deploymentConfig.maxSupply -
        totalSupply -
        _deploymentConfig.reservedSupply;
    }

    /// Check if the wallet is whitelisted for the presale
    function isWhitelisted(address wallet, bytes32[] calldata proof)
    public
    view
    returns (bool)
    {
        require(!_presaleMinted[wallet], "Already minted");

        bytes32 leaf = keccak256(abi.encodePacked(wallet));

        return
        MerkleProof.verify(proof, _runtimeConfig.presaleMerkleRoot, leaf);
    }

    /// Contract owner address
    /// @dev Required for easy integration with OpenSea
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

        _revokeRole(ADMIN_ROLE, _deploymentConfig.owner);
        _revokeRole(DEFAULT_ADMIN_ROLE, _deploymentConfig.owner);

        address previousOwner = _deploymentConfig.owner;
        _deploymentConfig.owner = newOwner;

        _grantRole(ADMIN_ROLE, _deploymentConfig.owner);
        _grantRole(DEFAULT_ADMIN_ROLE, _deploymentConfig.owner);

        emit OwnershipTransferred(previousOwner, newOwner);
    }

    /// Transfer contract ownership
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
        require(
            amount <= _deploymentConfig.reservedSupply,
            "Not enough reserved"
        );

        _deploymentConfig.reservedSupply -= amount;
        _mintTokensFromReserve(to, amount);
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

    RuntimeConfig internal _runtimeConfig;
    DeploymentConfig internal _deploymentConfig;

    bool internal _preventInitialization;

    mapping(address => bool) internal _presaleMinted;

    function _sendProviderFee() internal
    {
        if(msg.value != 0){
            // 2.5% of the transaction value
            uint256 splitValue = SafeMath.mul(SafeMath.div(msg.value, 1000), 25);
            payable(_deploymentConfig.providerAddress).transfer(splitValue);
        }
    }

    /// @dev Internal function for performing token mints
    function _mintTokens(address to, uint256 amount) internal {
        require(amount <= _deploymentConfig.tokensPerMint, "Amount too large");
        require(amount <= availableSupply(), "Not enough tokens left");

        // Update totalSupply only once with the total minted amount
        totalSupply += amount;

        // Send fee to provider
        _sendProviderFee();

        // Mint the required amount of tokens,
        // starting with the highest token ID
        for (uint256 i = 1; i <= amount; i++) {
            _safeMint(to, totalSupply - i);
        }
    }

    /// @dev Internal function for performing token mints from reserve (no tokensPerMint limit)
    function _mintTokensFromReserve(address to, uint256 amount) internal {
        require(amount <= availableSupply(), "Not enough tokens left");

        // Update totalSupply only once with the total minted amount
        totalSupply += amount;

        // Mint the required amount of tokens,
        // starting with the highest token ID
        for (uint256 i = 1; i <= amount; i++) {
            _safeMint(to, totalSupply - i);
        }
    }

    /// Validate deployment config
    function _validateDeploymentConfig(DeploymentConfig memory config)
    internal
    pure
    {
        require(config.maxSupply > 0, "Maximum supply must be non-zero");
        require(config.tokensPerMint > 0, "Tokens per mint must be non-zero");
        require(
            config.treasuryAddress != address(0),
            "Treasury address cannot be the null address"
        );
        require(config.owner != address(0), "Contract must have an owner");
        require(
            config.reservedSupply <= config.maxSupply,
            "Reserve must be less than maximum supply"
        );
    }

    /// Validate a runtime configuration change
    function _validateRuntimeConfig(RuntimeConfig calldata config)
    internal
    view
    {
        // Can't set royalties to more than 100%
        require(config.royaltiesBps <= ROYALTIES_BASIS, "Royalties too high");

        // If metadata is updatable, we don't have any other limitations
        if (_runtimeConfig.metadataUpdatable) return;

        // If it isn't, has we can't allow the flag to change anymore
        require(
            _runtimeConfig.metadataUpdatable == config.metadataUpdatable,
            "Cannot unfreeze metadata"
        );

        // We also can't allow base URI to change
        require(
            keccak256(abi.encodePacked(_runtimeConfig.baseURI)) ==
            keccak256(abi.encodePacked(config.baseURI)),
            "Metadata is frozen"
        );
    }

    /// @dev See {IERC165-supportsInterface}.
    function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721, AccessControl, ERC2981)
    returns (bool)
    {
        return
        ERC721.supportsInterface(interfaceId) ||
        AccessControl.supportsInterface(interfaceId) ||
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

        return
        bytes(_runtimeConfig.baseURI).length > 0
        ? string(
            abi.encodePacked(_runtimeConfig.baseURI, tokenId.toString())
        )
        : _runtimeConfig.prerevealTokenURI;
    }

    /// @dev Need name() to support setting it in the initializer instead of constructor
    function name() public view override returns (string memory) {
        return _deploymentConfig.name;
    }

    /// @dev Need symbol() to support setting it in the initializer instead of constructor
    function symbol() public view override returns (string memory) {
        return _deploymentConfig.symbol;
    }

    /// @dev ERC2981 token royalty info
    function royaltyInfo(uint256, uint256 salePrice)
    external
    override
    view
    returns (address receiver, uint256 royaltyAmount)
    {
        receiver = _runtimeConfig.royaltiesAddress;
        royaltyAmount =
        (_runtimeConfig.royaltiesBps * salePrice) /
        ROYALTIES_BASIS;
    }

    /// @dev OpenSea contract metadata
    function contractURI() external view returns (string memory) {
        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                    // solium-disable-next-line quotes
                        '{"seller_fee_basis_points": ', // solhint-disable-line quotes
                        _runtimeConfig.royaltiesBps.toString(),
                    // solium-disable-next-line quotes
                        ', "fee_recipient": "', // solhint-disable-line quotes
                        uint256(uint160(_runtimeConfig.royaltiesAddress))
                        .toHexString(20),
                    // solium-disable-next-line quotes
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

    /// Check if enough payment was provided to mint `amount` number of tokens
    modifier paymentProvided(uint256 amount) {
        require(
            msg.value >= amount * _runtimeConfig.mintPrice,
            "Payment too small"
        );
        _;
    }

    /***********************
     * Convenience getters *
     ***********************/

    function maxSupply() public view returns (uint256) {
        return _deploymentConfig.maxSupply;
    }

    function reservedSupply() public view returns (uint256) {
        return _deploymentConfig.reservedSupply;
    }

    function mintPrice() public view returns (uint256) {
        return _runtimeConfig.mintPrice;
    }

    function tokensPerMint() public view returns (uint256) {
        return _deploymentConfig.tokensPerMint;
    }

    function treasuryAddress() public view returns (address) {
        return _deploymentConfig.treasuryAddress;
    }

    function publicMintStart() public view returns (uint256) {
        return _runtimeConfig.publicMintStart;
    }

    function presaleMintStart() public view returns (uint256) {
        return _runtimeConfig.presaleMintStart;
    }

    function presaleMerkleRoot() public view returns (bytes32) {
        return _runtimeConfig.presaleMerkleRoot;
    }

    function baseURI() public view returns (string memory) {
        return _runtimeConfig.baseURI;
    }

    function metadataUpdatable() public view returns (bool) {
        return _runtimeConfig.metadataUpdatable;
    }

    function prerevealTokenURI() public view returns (string memory) {
        return _runtimeConfig.prerevealTokenURI;
    }
}