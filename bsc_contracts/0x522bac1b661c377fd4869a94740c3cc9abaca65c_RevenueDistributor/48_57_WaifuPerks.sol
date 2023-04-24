// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "../revenue/EquityRevenueHolder.sol";

/*
 * ERC721 NFTs that give the holders various benefits: increased rewards,
 * reduced claim tax, increased node refund. Tokens have tiers and can be
 * upgraded, higher tiers give bigger benefits. NFTs are minted and upgraded
 * by the PerkSaleHelper.
 */
contract WaifuPerks is
    Initializable,
    ERC721Upgradeable,
    ERC721EnumerableUpgradeable,
    ERC721PausableUpgradeable,
    AccessControlEnumerableUpgradeable,
    UUPSUpgradeable
{
    using StringsUpgradeable for uint256;

    /* ===== CONSTANTS ===== */

    bytes32 public constant URI_SETTER_ROLE = keccak256("URI_SETTER_ROLE");
    // PERK_SALE_HELPER_ROLE should be granted to PerkSaleHelper
    bytes32 public constant PERK_SALE_HELPER_ROLE =
        keccak256("PERK_SALE_HELPER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    // precision for percentage
    uint256 public constant PRECISION = 10000;

    /*
     * this value isn't expected to change,
     * let's save gas by making them constant
     */
    uint256 public constant TIER_COUNT = 5;

    /* ===== GENERAL ===== */

    EquityRevenueHolder public equityRevenueHolder;

    uint256[TIER_COUNT] private _tierPercentageBenefits;
    // token ID => token tier
    mapping(uint256 => uint256) public tokenTiers;

    // token ID => path appended to base URI to get the token URI
    mapping(uint256 => string) public tokenPaths;
    string public baseURI;
    // used if token path is not set with ID and tier appended
    string public fallbackURI;
    string public uriSeparator; // separator between ID and tier

    uint256 public supplyCap;

    /* ===== EVENTS ===== */

    event BaseURISet(string newBaseURI);
    event FallbackURISet(string newFallbackURI);
    event URISeparatorSet(string newURISeparator);
    event TokenUpgraded(uint256 indexed tokenId, uint256 tierNumber, uint256 newTier);
    event TokenPathSet(uint256 indexed tokenId, string tokenPath);

    /* ===== CONSTRUCTOR ===== */

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        EquityRevenueHolder _equityRevenueHolder,
        uint256[TIER_COUNT] calldata tierPercentageBenefits,
        uint256 _supplyCap,
        address admin
    ) public initializer {
        __ERC721_init("Kohai Clan", "KOHAI");
        __ERC721Enumerable_init();
        __ERC721Pausable_init();
        __AccessControlEnumerable_init();
        __UUPSUpgradeable_init();

        equityRevenueHolder = _equityRevenueHolder;
        _tierPercentageBenefits = tierPercentageBenefits;
        supplyCap = _supplyCap;

        _pause();

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(URI_SETTER_ROLE, admin);
        _grantRole(PAUSER_ROLE, admin);
        _grantRole(UPGRADER_ROLE, admin);

        if (admin != _msgSender()) {
            _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        }
    }

    /* ===== VIEWABLE ===== */

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        _requireMinted(tokenId);
        
        string memory tokenPath = tokenPaths[tokenId];

        if (bytes(tokenPath).length == 0) {
            // use fallback URI with ID and tier appended
            return string(
                abi.encodePacked(
                    fallbackURI,
                    tokenId.toString(),
                    uriSeparator,
                    tokenTiers[tokenId].toString()
                )
            ); 
        } else {
            // use base URI with tokenPath appended
            return string(
                abi.encodePacked(
                    baseURI,
                    tokenPath
                )
            );
        }
    }

    function getTierPercentageBenefits()
        public
        view
        returns (uint256[TIER_COUNT] memory)
    {
        return _tierPercentageBenefits;
    }

    function getMaxPercentageBenefit() public view returns (uint256) {
        return _tierPercentageBenefits[TIER_COUNT - 1];
    }

    function getPercentageBenefitOf(address account)
        public
        view
        returns (uint256)
    {
        if (equityRevenueHolder.balanceOf(account) > 0) {
            // max benefit for ERH holders
            return _tierPercentageBenefits[TIER_COUNT - 1];
        }

        uint256 balance = balanceOf(account);
        if (balance == 0) return 0;

        uint256 highestTier;
        for (uint256 i = 0; i < balance; i++) {
            uint256 tokenId = tokenOfOwnerByIndex(account, i);
            uint256 tokenTier = tokenTiers[tokenId];
            
            if (tokenTier > highestTier) {
                highestTier = tokenTier;
                // exit loop if max tier found
                if (highestTier == TIER_COUNT - 1) break;
            }
        }

        return _tierPercentageBenefits[highestTier];
    }
    /* ===== FUNCTIONALITY ===== */

    function mint(
        address to
    ) public whenNotPaused onlyRole(PERK_SALE_HELPER_ROLE) {
        // no burning, use total supply to assign ids
        _safeMint(to, totalSupply());
    }

    function mintUpgraded(
        address to,
        uint256 tier
    ) public whenNotPaused onlyRole(PERK_SALE_HELPER_ROLE) {
        // no burning, use total supply to assign ids
        uint256 tokenId = totalSupply();

        _safeMint(to, tokenId);
        _upgrade(tokenId, tier);
    }

    function upgrade(
        uint256 tokenId,
        uint256 tierNumber
    ) public whenNotPaused onlyRole(PERK_SALE_HELPER_ROLE) {
        _upgrade(tokenId, tierNumber);
    }

    /* ===== MUTATIVE ===== */

    function setBaseURI(string calldata newBaseURI)
        external
        onlyRole(URI_SETTER_ROLE)
    {
        baseURI = newBaseURI;

        emit BaseURISet(newBaseURI);
    }

    function setFallbackURI(string calldata newFallbackURI)
        external
        onlyRole(URI_SETTER_ROLE)
    {
        fallbackURI = newFallbackURI;

        emit FallbackURISet(newFallbackURI);
    }

    function setURISeparator(string calldata newURISeparator)
        external
        onlyRole(URI_SETTER_ROLE)
    {
        uriSeparator = newURISeparator;

        emit URISeparatorSet(newURISeparator);
    }

    function setTokenPath(
        uint256 tokenId,
        string calldata path
    ) external onlyRole(URI_SETTER_ROLE) {
        tokenPaths[tokenId] = path;

        emit TokenPathSet(tokenId, path);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /* ===== INTERNAL ===== */

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _upgrade(uint256 tokenId, uint256 tierNumber) private {
        require(tierNumber > 0, "WaifuPerks: upgrading 0 tiers");

        uint256 newTier = tokenTiers[tokenId] + tierNumber;

        require(
            newTier < TIER_COUNT,
            "WaifuPerks: max tier exceeded"
        );

        tokenTiers[tokenId] = newTier;

        emit TokenUpgraded(tokenId, tierNumber, newTier);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    )
        internal
        override(
            ERC721Upgradeable,
            ERC721EnumerableUpgradeable,
            ERC721PausableUpgradeable
        )
    {
        if (from == address(0)) {
            require(
                totalSupply() < supplyCap,
                "WaifuPerks: max supply reached"
            );
        } else if (to == address(0)) {
            revert("WaifuPerks: burning not allowed");
        }

        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyRole(UPGRADER_ROLE)
        override
    {}

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(
            ERC721Upgradeable,
            ERC721EnumerableUpgradeable,
            AccessControlEnumerableUpgradeable
        )
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}