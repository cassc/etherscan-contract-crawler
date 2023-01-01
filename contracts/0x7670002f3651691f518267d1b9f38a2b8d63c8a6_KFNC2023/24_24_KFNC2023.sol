// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import {IKFNC2023} from "./IKFNC2023.sol";
import {IOperatorDenylistRegistry} from "./IOperatorDenylistRegistry.sol";

/// @title KFNC2023
/// @author Kfish n Chips
/// @notice HAPPY NEW YEAR 2023
/// @dev This is an upgradeable contract using UUPSUpgradeable (IERC1822Proxiable / ERC1967Proxy) from OpenZeppelin
/// @custom:security-contact [email protected]
contract KFNC2023 is
    Initializable,
    ERC721Upgradeable,
    ERC2981Upgradeable,
    PausableUpgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable,
    IKFNC2023
{
    using CountersUpgradeable for CountersUpgradeable.Counter;

    /// @notice TokenID counter
    CountersUpgradeable.Counter private _tokenIdCounter;
    /// @notice Minting Time
    uint256 private mintTS;
    /// @notice Total max supply
    uint256 public maxSupply;
    /// @notice The metadata url
    string public metadataURI;
    /// @notice Contract Metadata
    string public contractURI;

    /// @notice Mapping address to to boolen (AlreadyMinted)
    mapping(address => bool) private _minters;

    /// @notice Operator Denylist Registry
    IOperatorDenylistRegistry public operatorDenylistRegistry;

    /// @notice Used to set the Mint Timestamp
    /// @dev Only callable by Owner
    /// @param mintTS_ the mew timestamp
    /// Emits an {MintTimestampChanged} event.
    function setMintTS(uint256 mintTS_) external onlyOwner {
        if (mintTS_ < block.timestamp) revert InvalidTimestamp(); // solhint-disable-line not-rely-on-time
        emit MintTimestampChanged(msg.sender, mintTS, mintTS_);
        mintTS = mintTS_;
    }

    /// @notice Used to set the metadata url
    /// @dev Only callable by Owner
    /// @param newMetadataURI the metadata url
    /// Emits an {MetadataURLChanged} event.
    function setMetadataURI(string memory newMetadataURI) external onlyOwner {
        if (bytes(newMetadataURI).length == 0) revert InvalidMetadataURI();
        emit MetadataURIChanged(msg.sender, metadataURI, newMetadataURI);
        metadataURI = newMetadataURI;
    }

    /// @notice Used to set the contractURI
    /// @dev Only callable by Owner
    /// @param newContractURI The base URI
    /// Emits an {ContractMetadataURIChanged} event.
    function setContractURI(string calldata newContractURI) external onlyOwner {
        if (bytes(newContractURI).length == 0) revert InvalidContractMetadataURI();
        emit ContractMetadataURIChanged(msg.sender, contractURI, newContractURI);
        contractURI = newContractURI;
    }

    /// @notice Sets the royalty information that all ids in this contract will default to.
    /// @dev Royalty is specified as a fraction of sale price. {_feeDenominator} is overridable but defaults to 10000, meaning the
    /// fee is specified in basis points by default.
    /// @param receiver cannot be the zero address.
    /// @param feeNumerator cannot be greater than the fee denominator.
    /// Emits an {DefaultRoyaltyChanged} event.
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyOwner {
        emit DefaultRoyaltyChanged(msg.sender, receiver, feeNumerator);
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    /// @notice Used to set the Denylist Registry
    /// @dev Only callable by Owner
    /// @param newOperatorDenylistRegistry The new Operator Denylist Registry
    /// Emits an {OperatorDenylistRegistryChanged} event.
    function setOperatorDenylistRegistry(address newOperatorDenylistRegistry) external onlyOwner {
        if (newOperatorDenylistRegistry == address(0)) revert InvalidOperatorDenylistRegistry();
        emit OperatorDenylistRegistryChanged(msg.sender, address(operatorDenylistRegistry), newOperatorDenylistRegistry);
        operatorDenylistRegistry = IOperatorDenylistRegistry(newOperatorDenylistRegistry);
    }

    /// @notice Initializer function which replaces constructor for upgradeable contracts
    /// @dev This should be called at deploy time
    function initialize(
        string memory name_,
        string memory symbol_,
        string memory metadataURI_,
        string memory contractURI_,
        uint256 maxSupply_,
        uint256 mintTS_,
        address operatorDenylistRegistry_
    ) external initializer {
        __UUPSUpgradeable_init();
        __ERC721_init(name_, symbol_);
        __Ownable_init();
        __ERC2981_init();
        __Pausable_init();

        _tokenIdCounter.increment();
        metadataURI = metadataURI_;
        contractURI = contractURI_;
        maxSupply = maxSupply_;
        mintTS = mintTS_;
        operatorDenylistRegistry = IOperatorDenylistRegistry(operatorDenylistRegistry_);
        _setDefaultRoyalty(msg.sender, 750);
    }

    /// @notice Triggers stopped state.
    /// @dev The contract must not be paused.
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Returns to normal state.
    /// @dev The contract must be paused.
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @notice Mints a token to a msg.sender.
    /// @dev Only one mint per address and only EoA can mint
    function mint() external {
        if (block.timestamp < mintTS) revert MintingNotAvailable(); // solhint-disable-line not-rely-on-time
        if (msg.sender != tx.origin) revert NonEoA(); // solhint-disable-line avoid-tx-origin
        if (_minters[msg.sender]) revert AlreadyMinted();
        if (_tokenIdCounter.current() > maxSupply) revert SupplyExceeded();
        _mint(msg.sender);
    }

    /// @notice Mints a token to a `to`
    /// @dev Only one mint per address. Only callable by Owner
    /// @param to The token recipient
    function safeMint(address to) external onlyOwner {
        if (_minters[to]) revert AlreadyMinted();
        if (_tokenIdCounter.current() > maxSupply) revert SupplyExceeded();
        _mint(to);
    }

    /// @notice Return total minted
    /// @return total minted
    function totalSupply() external view returns (uint256) {
        return _tokenIdCounter.current() - 1;
    }

    /// @dev See {IERC165-supportsInterface}.
    /// @inheritdoc	ERC165Upgradeable
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC2981Upgradeable, ERC721Upgradeable)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981Upgradeable).interfaceId ||
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /// @dev See See {IERC721Metadata-tokenURI}.
    /// @inheritdoc	ERC721Upgradeable
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        _requireMinted(tokenId);

        return metadataURI;
    }

    /// @notice Mints a token to a `to`
    /// @dev Only one mint per address
    /// @param to The token recipient
    function _mint(address to) internal {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _minters[to] = true;
        _safeMint(to, tokenId);
    }

    /// @dev See See {IERC721-setApprovalForAll}.
    /// @inheritdoc	ERC721Upgradeable
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual override whenNotPaused {
        if(operatorDenylistRegistry.isOperatorDenied(operator)) revert OperatorDenied();
        super._setApprovalForAll(owner, operator, approved);
    }

    /// @inheritdoc	ERC721Upgradeable
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal virtual override whenNotPaused {
        if(operatorDenylistRegistry.isOperatorDenied(msg.sender)) revert OperatorDenied();
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    /// @inheritdoc UUPSUpgradeable
    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {} // solhint-disable-line no-empty-blocks
}