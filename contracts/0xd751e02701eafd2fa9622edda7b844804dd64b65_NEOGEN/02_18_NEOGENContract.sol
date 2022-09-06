// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

contract NEOGENContract is ERC721A, ERC2981, AccessControl, Initializable {
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
        // The maximum number of tokens that can be minted in this collection.
        uint256 maxSupply;
    }

    /// Updatable by admins and owner
    struct RuntimeConfig {
        // Minting price per token.
        uint256 mintPrice;
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
        // Ending timestamp for whitelisted/presale minting.
        uint256 presaleMintEnd;
        // Starting timestamp for whitelisted/presale minting.
        uint256 freeMintStart;
        // Ending timestamp for whitelisted/presale minting.
        uint256 freeMintEnd;
        // Pre-reveal token URI for placholder metadata. This will be returned for all token IDs until a `baseURI`
        // has been set.
        string prerevealTokenURI;
        // Root of the Merkle tree of whitelisted addresses. This is used to check if a wallet has been whitelisted
        // for presale minting.
        bytes32 whitelistMerkleRoot;
        // This is used to check if a wallet has been freelisted for minting.
        bytes32 freeMintMerkleRoot;
        // Secondary market royalties in basis points (100 bps = 1%)
        uint256 royaltiesBps;
        // Address for royalties
        address royaltiesAddress;
        // Treasury address is the address where minting fees can be withdrawn to.
        // Use `withdrawFees()` to transfer the entire contract balance to the treasury address.
        address payable treasuryAddress;
    }

    struct ContractInfo {
        DeploymentConfig deploymentConfig;
        RuntimeConfig runtimeConfig;
    }

    /*************
     * Events *
     *************/

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    event UpdateRuntimeConfig();

    /*************
     * Constants *
     *************/

    /// Admin role
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    // Basis for calculating royalties.
    // This has to be 10k for royaltiesBps to be in basis points.
    uint16 private constant ROYALTIES_BASIS = 10000;

    // Max supply constants per mint
    uint16 private constant PUBLIC_MAX_SUPPLY = 5;
    uint16 private constant PRESALE_MAX_SUPPLY = 3;
    uint16 private constant FREE_MAX_SUPPLY = 1;
    uint16 private constant INO_MAX_SUPPLY = 5000;

    /***************************
     * Contract initialization *
     ***************************/

    constructor() ERC721A("", "") {
        _preventInitialization = true;
    }

    /// Contract initializer
    function initialize(
        DeploymentConfig memory deploymentConfig,
        RuntimeConfig memory runtimeConfig
    ) public initializer {
        require(!_preventInitialization, "Cannot be initialized");
        require(msg.sender == deploymentConfig.owner, "Owner is not msg.sender");

        _validateDeploymentConfig(deploymentConfig);

        _runtimeConfig.metadataUpdatable = true;
        _validateRuntimeConfig(runtimeConfig);

        _grantRole(ADMIN_ROLE, msg.sender);

        _deploymentConfig = deploymentConfig;
        _runtimeConfig = runtimeConfig;
    }

    /****************
     * User actions *
     ****************/

    /// Mint tokens
    function mint(uint256 amount) external payable paymentProvided(amount) {
        require(mintingActive(), "Minting has not started yet");
        require(amount <= PUBLIC_MAX_SUPPLY, "Amount too large");

        _mintTokens(msg.sender, amount);
    }

    /// Mint tokens if the wallet has been whitelisted
    function presaleMint(uint256 amount, bytes32[] calldata proof)
        external
        payable
        paymentProvided(amount)
    {
        require(presaleActive(), "Presale has not active");
        require(
            isWhitelisted(msg.sender, proof),
            "Not whitelisted for presale"
        );
        require(amount <= PRESALE_MAX_SUPPLY, "Amount too large");

        _presaleMinted[msg.sender] = true;
        _mintTokens(msg.sender, amount);
    }

    /// Mint tokens for freeMint
    function freeMint(bytes32[] calldata proof) external {
        require(freeMintActive(), "Free Mint has not active");
        require(isFreelisted(msg.sender, proof), "Not freelisted for minting");

        _freeMinted[msg.sender] = true;
        _mintTokens(msg.sender, FREE_MAX_SUPPLY);
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
        return
            block.timestamp > _runtimeConfig.presaleMintStart &&
            block.timestamp < _runtimeConfig.presaleMintEnd;
    }

    /// Check if free minting is active
    function freeMintActive() public view returns (bool) {
        return
            block.timestamp > _runtimeConfig.freeMintStart &&
            block.timestamp < _runtimeConfig.freeMintEnd;
    }

    /// Get the number of tokens still available for minting
    function availableSupply() public view returns (uint256) {
        return _deploymentConfig.maxSupply - totalSupply();
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
            MerkleProof.verify(proof, _runtimeConfig.whitelistMerkleRoot, leaf);
    }

    /// Check if the wallet is freeMinted
    function isFreelisted(address wallet, bytes32[] calldata proof)
        public
        view
        returns (bool)
    {
        require(!_freeMinted[wallet], "Already minted");

        bytes32 leaf = keccak256(abi.encodePacked(wallet));

        return
            MerkleProof.verify(proof, _runtimeConfig.freeMintMerkleRoot, leaf);
    }

    /// Contract owner address
    /// @dev Required for easy integration with OpenSea
    function owner() external view returns (address) {
        return _deploymentConfig.owner;
    }

    /*******************
     * Access controls *
     *******************/

    /// Transfer contract ownership
    function transferOwnership(address newOwner) external onlyRole(ADMIN_ROLE) {
        require(newOwner != _deploymentConfig.owner, "Already the owner");

        _transferOwnership(newOwner);
    }

    /// Grant Admin Rights
    function grantAdminRights(address newAdmin) external onlyRole(ADMIN_ROLE) {
        require(msg.sender == _deploymentConfig.owner, "Only owner can grant Admin Rights");

        _grantRole(ADMIN_ROLE, newAdmin);
    }

    /// Revoke Admin Rights
    function revokeAdminRights(address _address) external onlyRole(ADMIN_ROLE) {
        require(msg.sender == _deploymentConfig.owner, "Only owner can revoke Admin Rights");

        _revokeRole(ADMIN_ROLE, _address);
    }


    /*****************
     * Admin actions *
     *****************/

    /// ioTranfer for Launchpades
    function INO(address to, uint256 amount) external onlyRole(ADMIN_ROLE) {
        require(amount <= INO_MAX_SUPPLY, "Amount too large");
        _mintTokens(to, amount);
    }

    /// Get full contract information
    /// @dev Convenience helper
    function getInfo() external view returns (ContractInfo memory info) {
        info.deploymentConfig = _deploymentConfig;
        info.runtimeConfig = _runtimeConfig;
    }

    /// Update contract configuration
    /// @dev Callable by admin roles only
    function updateConfig(RuntimeConfig memory newConfig)
        external
        onlyRole(ADMIN_ROLE)
    {
        _validateRuntimeConfig(newConfig);
        _runtimeConfig = newConfig;

        emit UpdateRuntimeConfig();
    }

    /// Withdraw minting fees to the treasury address
    /// @dev Callable by admin roles only
    function withdrawFees() external onlyRole(ADMIN_ROLE) {
        _runtimeConfig.treasuryAddress.sendValue(address(this).balance);
    }

    /*************
     * Internals *
     *************/

    /// Contract configuration
    RuntimeConfig internal _runtimeConfig;
    DeploymentConfig internal _deploymentConfig;

    /// Flag for disabling initalization for template contracts
    bool internal _preventInitialization;

    /// Mapping for tracking presale mint status
    mapping(address => bool) internal _presaleMinted;
    mapping(address => bool) internal _freeMinted;

    /// @dev Internal function for performing token mints
    function _mintTokens(address to, uint256 amount) internal {
        require(amount <= availableSupply(), "Not enough tokens left");

        _safeMint(to, amount);
    }

    /// Validate deployment config
    function _validateDeploymentConfig(DeploymentConfig memory config)
        internal
        pure
    {
        require(config.maxSupply > 0, "Maximum supply must be non-zero");        
        require(config.owner != address(0), "Contract must have an owner");
    }

    /// Validate a runtime configuration change
    function _validateRuntimeConfig(RuntimeConfig memory config)
        internal
        view
    {
        // Can't set royalties to more than 100%
        require(config.royaltiesBps <= ROYALTIES_BASIS, "Royalties too high");

        // check if config addresses is non-zero
        require(config.royaltiesAddress != address(0), "Royalty address cannot be null");
        require(config.treasuryAddress != address(0), "Treasury address cannot be null");

        // check if URI`s is non-zero
        // require(bytes(config.baseURI).length != 0, "BaseURI string cannot be null");
        require(bytes(config.prerevealTokenURI).length != 0, "PrerevealURI string cannot be null");

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

    /// Internal function without any checks for performing the ownership transfer
    function _transferOwnership(address newOwner) internal {
        address previousOwner = _deploymentConfig.owner;
        _revokeRole(ADMIN_ROLE, previousOwner);

        _deploymentConfig.owner = newOwner;
        _grantRole(ADMIN_ROLE, newOwner);

        emit OwnershipTransferred(previousOwner, newOwner);
    }

    /// @dev See {IERC165-supportsInterface}.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721A, AccessControl, ERC2981)
        returns (bool)
    {
        return
            ERC721A.supportsInterface(interfaceId) ||
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
        public
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        receiver = _runtimeConfig.royaltiesAddress;
        royaltyAmount = (_runtimeConfig.royaltiesBps * salePrice) / ROYALTIES_BASIS;        
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
            msg.value == amount * _runtimeConfig.mintPrice,
            "Cost is incorrect"
        );
        _;
    }

    /***********************
     * Convenience getters *
     ***********************/

    function maxSupply() external view returns (uint256) {
        return _deploymentConfig.maxSupply;
    }

    function treasuryAddress() external view returns (address) {
        return _runtimeConfig.treasuryAddress;
    }

    function mintPrice() external view returns (uint256) {
        return _runtimeConfig.mintPrice;
    }

    function publicMintStart() external view returns (uint256) {
        return _runtimeConfig.publicMintStart;
    }

    function presaleMintStart() external view returns (uint256) {
        return _runtimeConfig.presaleMintStart;
    }

    function presaleMintEnd() external view returns (uint256) {
        return _runtimeConfig.presaleMintEnd;
    }

    function freeMintStart() external view returns (uint256) {
        return _runtimeConfig.freeMintStart;
    }

    function freeMintEnd() external view returns (uint256) {
        return _runtimeConfig.freeMintEnd;
    }

    function whitelistMerkleRoot() external view returns (bytes32) {
        return _runtimeConfig.whitelistMerkleRoot;
    }

    function freeMintMerkleRoot() external view returns (bytes32) {
        return _runtimeConfig.freeMintMerkleRoot;
    }

    function baseURI() external view returns (string memory) {
        return _runtimeConfig.baseURI;
    }

    function metadataUpdatable() external view returns (bool) {
        return _runtimeConfig.metadataUpdatable;
    }

    function prerevealTokenURI() external view returns (string memory) {
        return _runtimeConfig.prerevealTokenURI;
    }
}