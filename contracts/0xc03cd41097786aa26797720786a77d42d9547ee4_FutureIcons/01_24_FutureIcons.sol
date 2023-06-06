// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import { ERC721Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import { PausableUpgradeable } from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import { AccessControlUpgradeable } from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { ECDSAUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract FutureIcons is
    Initializable,
    ERC721Upgradeable,
    PausableUpgradeable,
    AccessControlUpgradeable,
    UUPSUpgradeable
{
    using ECDSAUpgradeable for bytes32;

    // Access control
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant MINT_SIGNER_ROLE = keccak256("MINT_SIGNER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    // Collection type
    struct Collection {
        bool exists;
        bool isMintableWithIcons;
        uint256 price;
        uint256 priceInIcons;
        uint256 maxSupply;
        uint256 maxMint;
        uint256 supply;
    }

    // Mapping from collection ID to collection details
    mapping(uint256 => Collection) public collections;

    // Next available collection ID
    uint256 private _nextCollectionId;

    // Base URI
    string private _baseTokenURI;

    // Minting signature domain separator
    bytes32 private _domainSeparator;

    // The minter typehash used in the minting signature
    bytes32 private constant MINTER_TYPEHASH = keccak256("Minter(address spender)");

    // Constants for token ID generation
    uint256 private constant ONE_MILLION = 1_000_000;
    uint256 private constant MAX_SUPPLY_LIMIT = 100_000;

    // $ICONS token
    IERC20 public icons;

    // Events
    event Mint(address indexed to, uint256 indexed tokenId);
    event CollectionUpdated(uint256 indexed collectionId);
    event Withdraw(address indexed to);

    // Custom errors
    error InvalidCollectionDetails();
    error InvalidCollection();
    error CollectionNotMintable();
    error CollectionNotMintableWithICONS();
    error InvalidMintSigner();
    error InvalidTokenAmount();
    error InvalidEtherAmount();
    error TooLowICONSAllowance();
    error ExceedsMaxSupply();

    // Modifiers
    modifier onlyValidCollectionId(uint256 collectionId) {
        if (!collections[collectionId].exists) revert InvalidCollection();
        _;
    }

    modifier onlySigned(bytes calldata signature) {
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                _domainSeparator,
                keccak256(abi.encode(MINTER_TYPEHASH, msg.sender))
            )
        );

        if (!hasRole(MINT_SIGNER_ROLE, digest.recover(signature))) revert InvalidMintSigner();
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Initializes the contract.
     */
    function initialize(
        address defaultAdmin_,
        address manager_,
        address mintSigner_,
        address icons_
    ) public initializer {
        __ERC721_init("FutureIcons", "FTRICN");
        __Pausable_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin_);
        _grantRole(MANAGER_ROLE, manager_);
        _grantRole(MINT_SIGNER_ROLE, mintSigner_);
        _grantRole(UPGRADER_ROLE, defaultAdmin_);

        icons = IERC20(icons_);

        _domainSeparator = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes("FutureIcons")),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );

        _nextCollectionId = 1;
    }

    /**
     * @dev Pauses the contract.
     */
    function pause() external onlyRole(MANAGER_ROLE) {
        _pause();
    }

    /**
     * @dev Unpauses the contract.
     */
    function unpause() external onlyRole(MANAGER_ROLE) {
        _unpause();
    }

    /**
     * @dev Returns the total amount of tokens in a collection.
     */
    function collectionSupply(
        uint256 collectionId
    ) external view onlyValidCollectionId(collectionId) returns (uint256) {
        return collections[collectionId].supply;
    }

    /**
     * @dev Sets the base URI for {ERC721Upgradeable-tokenURI}.
     */
    function setBaseURI(string calldata baseURI) external onlyRole(MANAGER_ROLE) {
        _baseTokenURI = baseURI;
    }

    /**
     * @dev Adds a new collection to the contract.
     */
    function addCollection(
        bool isMintableWithIcons,
        uint256 price,
        uint256 priceInIcons,
        uint256 maxSupply,
        uint256 maxMint
    ) external onlyRole(MANAGER_ROLE) {
        if (price == 0 || maxSupply == 0 || maxSupply > MAX_SUPPLY_LIMIT || maxMint == 0)
            revert InvalidCollectionDetails();
        if (isMintableWithIcons && priceInIcons == 0) revert InvalidCollectionDetails();

        uint256 collectionId = _nextCollectionId;

        collections[collectionId].exists = true;
        collections[collectionId].isMintableWithIcons = isMintableWithIcons;
        collections[collectionId].price = price;
        collections[collectionId].priceInIcons = priceInIcons;
        collections[collectionId].maxSupply = maxSupply;
        collections[collectionId].maxMint = maxMint;
        collections[collectionId].supply = 0;

        _nextCollectionId++;
    }

    /**
     * @dev Updates the collection.
     */
    function updateCollection(
        uint256 collectionId,
        bool isMintableWithIcons,
        uint256 price,
        uint256 priceInIcons,
        uint256 maxSupply,
        uint256 maxMint
    ) external onlyRole(MANAGER_ROLE) onlyValidCollectionId(collectionId) {
        if (price == 0 || maxSupply == 0 || maxSupply > MAX_SUPPLY_LIMIT || maxMint == 0)
            revert InvalidCollectionDetails();
        if (isMintableWithIcons && priceInIcons == 0) revert InvalidCollectionDetails();
        if (maxSupply < collections[collectionId].supply) revert ExceedsMaxSupply();

        collections[collectionId].isMintableWithIcons = isMintableWithIcons;
        collections[collectionId].price = price;
        collections[collectionId].priceInIcons = priceInIcons;
        collections[collectionId].maxSupply = maxSupply;
        collections[collectionId].maxMint = maxMint;

        emit CollectionUpdated(collectionId);
    }

    /**
     * @dev Toggles the mintable with $ICONS status of a collection.
     */
    function toggleCollectionMintableWithIcons(
        uint256 collectionId
    ) external onlyRole(MANAGER_ROLE) onlyValidCollectionId(collectionId) {
        collections[collectionId].isMintableWithIcons = !collections[collectionId]
            .isMintableWithIcons;

        emit CollectionUpdated(collectionId);
    }

    /**
     * @dev Mints a token using ether.
     */
    function mint(
        uint256 collectionId,
        uint256 amount,
        bytes calldata signature
    ) public payable whenNotPaused onlySigned(signature) {
        Collection storage collection = collections[collectionId];

        if (!collection.exists) revert InvalidCollection();
        if (amount == 0 || amount > collection.maxMint) revert InvalidTokenAmount();
        if (collection.supply + amount > collection.maxSupply) revert ExceedsMaxSupply();
        if (msg.value != collection.price * amount) revert InvalidEtherAmount();

        uint256 nextTokenId = collectionId * ONE_MILLION + collection.supply;

        collection.supply += amount;

        _safeMintBatch(msg.sender, nextTokenId, amount);
    }

    /**
     * @dev Mints a token using $ICONS.
     */
    function mintWithIcons(
        uint256 collectionId,
        uint256 amount,
        bytes calldata signature
    ) public whenNotPaused onlySigned(signature) {
        Collection storage collection = collections[collectionId];

        if (!collection.exists) revert InvalidCollection();
        if (!collection.isMintableWithIcons) revert CollectionNotMintableWithICONS();
        if (amount == 0 || amount > collection.maxMint) revert InvalidTokenAmount();
        if (collection.supply + amount > collection.maxSupply) revert ExceedsMaxSupply();
        if (icons.allowance(msg.sender, address(this)) < collection.priceInIcons * amount)
            revert TooLowICONSAllowance();

        uint256 nextTokenId = collectionId * ONE_MILLION + collection.supply;

        collection.supply += amount;

        icons.transferFrom(msg.sender, address(this), collection.priceInIcons * amount);

        _safeMintBatch(msg.sender, nextTokenId, amount);
    }

    /**
     * @dev Withdraws the contracts ether balance to the owners address.
     */
    function withdraw() external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 balance = address(this).balance;

        if (balance > 0) {
            payable(msg.sender).transfer(balance);

            emit Withdraw(msg.sender);
        }
    }

    /**
     * @dev Withdraws the contracts $ICONS balance to the owners address.
     */
    function withdrawIcons() external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 balance = icons.balanceOf(address(this));

        if (balance > 0) {
            icons.approve(address(this), balance);
            icons.transferFrom(address(this), msg.sender, balance);

            emit Withdraw(msg.sender);
        }
    }

    /**
     * @dev Safely mints a batch of tokens.
     */
    function _safeMintBatch(address to, uint256 nextTokenId, uint256 amount) private {
        while (amount > 0) {
            _safeMint(to, nextTokenId);

            emit Mint(to, nextTokenId);

            // Unchecked arithmetic operations are safe here:
            // - the minimum value for `amount` is 0 which stops the loop; integer underflow is not possible
            // - the maximum value for `nextTokenId` depends on collectionId and collection maxSupply
            //   values which are set by an account with the `MANAGER_ROLE; integer overflow is only possible
            //   when more than 1.15e71 collections are created
            unchecked {
                nextTokenId++;
                amount--;
            }
        }
    }

    /**
     * @dev Authorizes the upgrade.
     */
    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyRole(UPGRADER_ROLE) {} // solhint-disable-line no-empty-blocks

    /**
     * @dev See {ERC721Upgradeable-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    /**
     * @dev See {ERC721Upgradeable-_baseURI}.
     */
    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * @dev Overrides required by Solidity.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721Upgradeable, AccessControlUpgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}