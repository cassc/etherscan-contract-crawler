// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./ERHPaymentSplitter.sol";

contract EquityRevenueHolder is
    Initializable,
    ERC721Upgradeable,
    ERC721PausableUpgradeable,
    ERC2981Upgradeable,
    AccessControlEnumerableUpgradeable,
    UUPSUpgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;

    /* ===== CONSTANTS ===== */

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant TRANSFERER_ROLE = keccak256("TRANSFERER_ROLE");
    bytes32 public constant LIMITS_ADMIN_ROLE = keccak256("LIMITS_ADMIN_ROLE");
    bytes32 public constant ADDRESS_ADMIN_ROLE =
        keccak256("ADDRESS_ADMIN_ROLE");
    bytes32 public constant ROYALTY_SETTER_ROLE =
        keccak256("ROYALTY_SETTER_ROLE");
    bytes32 public constant URI_SETTER_ROLE = keccak256("URI_SETTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    /* ===== GENERAL ===== */

    CountersUpgradeable.Counter private _tokenIdCounter;
    uint256 public supplyCap;

    bool private isRevealed;

    string private revealedURI;
    string private unrevealedURI;

    bool public transfersEnabled;
    mapping(address => bool) public accountTransfersEnabled;

    ERHPaymentSplitter erhPaymentSplitter;

    /* ===== EVENTS ===== */

    event TransfersEnabledSet(bool enabled);
    event AccountTransfersEnabledSet(address account, bool enabled);
    event DefaultRoyaltySet(address receiver, uint256 feeNumerator);

    /* ===== CONSTRUCTOR ===== */

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        uint256 _supplyCap,
        address admin
    )
        public
        initializer
    {
        __ERC721_init("EquityRevenueHolder", "ERH");
        __ERC721Pausable_init();
        __ERC2981_init();
        __AccessControlEnumerable_init();
        __UUPSUpgradeable_init();

        supplyCap = _supplyCap;

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(MINTER_ROLE, admin);
        _grantRole(TRANSFERER_ROLE, admin);
        _grantRole(LIMITS_ADMIN_ROLE, admin);
        _grantRole(ADDRESS_ADMIN_ROLE, admin);
        _grantRole(ROYALTY_SETTER_ROLE, admin);
        _grantRole(URI_SETTER_ROLE, admin);
        _grantRole(PAUSER_ROLE, admin);
        _grantRole(UPGRADER_ROLE, admin);

        if (admin != _msgSender()) {
            _grantRole(ADDRESS_ADMIN_ROLE, _msgSender());
        }
    }

    /* ===== VIEWABLE ===== */

    function totalSupply() external view returns (uint256) {
        return _tokenIdCounter.current();
    }

    /* ===== FUNCTIONALITY ===== */

    function safeMintNext(address to) public onlyRole(MINTER_ROLE) {
        _safeMintNext(to);
    }

    function safeMintNextBatch(
        address to,
        uint256 amount
    ) public onlyRole(MINTER_ROLE) {
        for (uint256 i = 0; i < amount; i++) {
            _safeMintNext(to);
        }
    }

    /* ===== MUTATIVE ===== */

    function setRevealedURI(string memory _revealedURI)
        external
        onlyRole(URI_SETTER_ROLE)
    {
        revealedURI = _revealedURI;
    }

    function setUnrevealedURI(string memory _unrevealedURI)
        external
        onlyRole(URI_SETTER_ROLE)
    {
        unrevealedURI = _unrevealedURI;
    }

    function setIsRevealed(bool _isRevealed)
        external
        onlyRole(URI_SETTER_ROLE)
    {
        isRevealed = _isRevealed;
    }

    function setTransfersEnabled(bool enabled)
        external
        onlyRole(LIMITS_ADMIN_ROLE)
    {
        transfersEnabled = enabled;

        emit TransfersEnabledSet(enabled);
    }

    function setAccountTransfersEnabled(address account, bool enabled)
        external
        onlyRole(LIMITS_ADMIN_ROLE)
    {
        accountTransfersEnabled[account] = enabled;

        emit AccountTransfersEnabledSet(account, enabled);
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator)
        external
        onlyRole(ROYALTY_SETTER_ROLE)
    {
        _setDefaultRoyalty(receiver, feeNumerator);

        emit DefaultRoyaltySet(receiver, feeNumerator);
    }

    function setERHPaymentSplitter(ERHPaymentSplitter _erhPaymentSplitter)
        external
        onlyRole(LIMITS_ADMIN_ROLE)
    {
        erhPaymentSplitter = _erhPaymentSplitter;
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /* ===== OVERRIDES ===== */

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(
            ERC721Upgradeable,
            ERC2981Upgradeable,
            AccessControlEnumerableUpgradeable
        )
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /* ===== INTERNAL ===== */

    function _safeMintNext(address to) private {
        uint256 tokenId = _tokenIdCounter.current();
        require(tokenId < supplyCap, "EquityRevenueHolder: cap reached");

        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        override
        returns (bool)
    {
        return hasRole(TRANSFERER_ROLE, spender) ||
            super._isApprovedOrOwner(spender, tokenId);
    }

    function _baseURI() internal view override returns (string memory) {
        return isRevealed ? revealedURI : unrevealedURI;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721Upgradeable, ERC721PausableUpgradeable) {
        require(
            transfersEnabled ||
            accountTransfersEnabled[from] ||
            from == address(0),
            "EquityRevenueHolder: transfers locked"
        );

        if (address(erhPaymentSplitter) != address(0)) {
            erhPaymentSplitter.autoRelease(tokenId);
        }

        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyRole(UPGRADER_ROLE)
        override
    {}
}