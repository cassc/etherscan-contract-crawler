// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "./interfaces/INFT.sol";

contract NFT is
    INFT,
    ERC2981,
    UUPSUpgradeable,
    ERC721EnumerableUpgradeable,
    AccessControlUpgradeable,
    PausableUpgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private _tokenIds;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    string internal _baseTokenURI;
    string private _contractURI;

    function initialize(
        string memory name,
        string memory symbol,
        string memory baseTokenURI
    ) public initializer {
        __UUPSUpgradeable_init_unchained();
        __AccessControl_init_unchained();
        __Pausable_init_unchained();

        __ERC721_init_unchained(name, symbol);
        _baseTokenURI = baseTokenURI;

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    // Mint item
    function mintItem(address user)
        external
        virtual
        onlyRole(MINTER_ROLE)
        returns (uint256)
    {
        uint256 newItemId = _tokenIds.current();
        _mint(user, newItemId);
        _tokenIds.increment();
        return newItemId;
    }

    // Set base URI
    function setBaseURI(string memory baseTokenURI)
        external
        virtual
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _baseTokenURI = baseTokenURI;
    }

    // Set default royalty
    function setDefaultRoyalty(address receiver, uint96 royalty)
        external
        virtual
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _setDefaultRoyalty(receiver, royalty);
    }

    // Set Contract URI
    function setContractURI(string memory newContractURI)
        external
        virtual
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _contractURI = newContractURI;
    }

    // Get base URI
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(
            IERC165,
            ERC2981,
            ERC721EnumerableUpgradeable,
            AccessControlUpgradeable
        )
        returns (bool)
    {
        if (interfaceId == type(IERC2981).interfaceId) {
            return true;
        }
        if (interfaceId == type(INFT).interfaceId) {
            return true;
        }
        return super.supportsInterface(interfaceId);
    }

    // UUPS proxy function
    function _authorizeUpgrade(address)
        internal
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {}

    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);
        _resetTokenRoyalty(tokenId);
    }

    function contractURI() external view virtual returns (string memory) {
        return _contractURI;
    }
}