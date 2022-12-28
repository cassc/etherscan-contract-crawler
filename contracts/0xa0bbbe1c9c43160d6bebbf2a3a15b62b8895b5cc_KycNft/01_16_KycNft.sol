// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.11;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";

import "./IKycNft.sol";

/**
    Error codes:
    N1 -> Provider: caller is not the provider
    N3 -> Mint: caller is not receiver
    N3 -> Mint: expired deadline
    N4 -> Mint: message cancelled
    N4 -> Mint: invalid signature
 */

contract KycNft is Initializable, ERC721Upgradeable, PausableUpgradeable, OwnableUpgradeable, IKycNft, EIP712Upgradeable {
    struct Gene {
        uint256 basic;
        uint256 reserved;
    }

    // ---- BEGIN: V1 Storage Layout
    // Default provider address
    address private defaultProvider;

    // Cancelled EIP712 messages stored by hash
    // hash -> cancelled (bool)
    mapping (bytes32 => bool) private UNUSED_cancelledMessages;

    string private baseUriString;

    // Mapping for tokenId genes
    mapping(uint256 => Gene) private UNUSED_genes;
    // ---- END: V1 Storage Layout

    // Events
    event LogDefaultProviderChanged(address indexed defaultProvider);
    event LogBaseUriStringChanged(string baseUriString);

    // Modifiers
    modifier onlyDefaultProvider() {
        require(msg.sender == defaultProvider, "N1");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier onlyMintWhenPaused(address from) {
        require(!paused() || from == address(0), "Pausable: transfer paused");
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(
        string memory _name,
        string memory _symbol,
        string memory _uri
    ) public initializer {
        __ERC721_init(_name, _symbol);
        __Pausable_init();
        __Ownable_init();
        __EIP712_init(_name, "1");

        // Set initial baseUriString
        baseUriString = _uri;

        // Pause transfers by default
        _pause();
    }

    /// Public
    /**
     * @custom:deprecated In version v2.1
     */
    function mint(
        uint256 /* basicGene */,
        uint256 /* deadline */,
        uint8 /* v */,
        bytes32 /* r */,
        bytes32 /* s */
    ) public {
        // Redirect to permissionless minting
        claim(msg.sender);
    }

    /**
     * @dev See {IKycNft-claim}.
     */
    function claim(address to) public {
        // Calculate tokenId from `to` address
        uint256 tokenId = addressToTokenId(to);
        _safeMint(to, tokenId);
    }

    /// EIP712
    /**
     * @dev See {IKycNft-DOMAIN_SEPARATOR}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        return _domainSeparatorV4();
    }

    /// Provider
    function getDefaultProvider() public view returns (address) {
        return defaultProvider;
    }

    /// Governance
    function safeMint(address to, uint256 tokenId) public onlyOwner {
        _safeMint(to, tokenId);
    }

    function setDefaultProvider(address _defaultProvider) public onlyOwner {
        defaultProvider = _defaultProvider;
        emit LogDefaultProviderChanged(_defaultProvider);
    }

    function setBaseUriString(string memory _baseUriString) public onlyOwner {
        baseUriString = _baseUriString;
        emit LogBaseUriStringChanged(_baseUriString);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    /// Private NFT functions
    /**
     * @dev See {ERC721Upgradeable-_baseURI}.
     */
    function _baseURI() internal view override returns (string memory) {
        return baseUriString;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        onlyMintWhenPaused(from)
        override
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /// Public Util functions
    function addressToTokenId(address receiver) public pure returns (uint256) {
        return uint256(uint160(receiver));
    }

    function tokenIdToAddress(uint256 tokenId) public pure returns (address) {
        return address(bytes20(bytes32(tokenId)));
    }

    function getChainId() external view returns (uint256) {
        return block.chainid;
    }

    function contractURI() public view returns (string memory) {
        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, "contract-metadata")) : "";
    }

    uint256[50] private __gap;
}