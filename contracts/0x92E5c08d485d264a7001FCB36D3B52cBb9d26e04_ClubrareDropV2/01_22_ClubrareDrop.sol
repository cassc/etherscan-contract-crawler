// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./Royalties.sol";
import "./utils/Roles.sol";

contract ClubrareDropV2 is
    Ownable,
    ERC721,
    ERC721Enumerable,
    ERC721URIStorage,
    Pausable,
    AccessControl,
    ERC721Burnable,
    Royalties,
    Role
{
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;
    address private _treasuryWallet;
    string public baseURI;
    string public contractURI;

    constructor(
        address _admin,
        address _marketplace,
        string memory _contractURI,
        string memory tokenURIPrefix
    ) ERC721("Clubrare Drop", "CBRD") {
        _treasuryWallet = _marketplace;
        baseURI = tokenURIPrefix;
        contractURI = _contractURI;
        _tokenIdCounter.increment();
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _grantRole(PAUSER_ROLE, _admin);
        _grantRole(MINTER_ROLE, _admin);
        _grantRole(MINTER_ROLE, _marketplace);
        _grantRole(TRANSFER_ROLE, _marketplace);
    }

    /// @dev Restricted to admins.
    modifier onlyAdmin() {
        require(isAdmin(msg.sender), "Restricted to members.");
        _;
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function setBaseURI(string memory _baseURI) external whenNotPaused onlyRole(DEFAULT_ADMIN_ROLE) {
        baseURI = _baseURI;
    }

    function setContractURI(string memory _contractURI) external whenNotPaused onlyRole(DEFAULT_ADMIN_ROLE) {
        contractURI = _contractURI;
    }

    function setMarketplaceAddress(address _marketplace) external whenNotPaused onlyRole(DEFAULT_ADMIN_ROLE) {
        _treasuryWallet = _marketplace;
    }

    function safeMint(string memory uri, uint256 value) public virtual onlyRole(MINTER_ROLE) returns (uint256) {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(_treasuryWallet, tokenId);
        _setTokenURI(tokenId, uri);

        if (value > 0) {
            _setTokenRoyalty(tokenId, _treasuryWallet, value);
        }
        return tokenId;
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721, IERC721) {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId) || hasRole(TRANSFER_ROLE, _msgSender()),
            "ERC721: caller is not token owner nor approved"
        );
        _transfer(from, to, tokenId);
    }

    /// @dev Return `true` if the `account` belongs to the admin.
    function isAdmin(address account) public view virtual returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, account);
    }

    /// @dev Add an account to the admin role. Restricted to admins.
    function addAdmin(address account) public virtual onlyAdmin {
        grantRole(DEFAULT_ADMIN_ROLE, account);
        grantRole(MINTER_ROLE, account);
    }

    /// @dev Remove oneself from the admin role.
    function renounceAdmin(address account) public virtual onlyAdmin {
        renounceRole(DEFAULT_ADMIN_ROLE, account);
        renounceRole(MINTER_ROLE, account);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function safeBurn(uint256 tokenId) external whenNotPaused onlyAdmin {
        _burn(tokenId);
    }

    function transferOwnership(address newOwner) public virtual override onlyOwner {
        _transferOwnership(newOwner);
        grantRole(DEFAULT_ADMIN_ROLE, newOwner);
        grantRole(MINTER_ROLE, newOwner);
    }

    // The following functions are overrides required by Solidity.
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, super.tokenURI(tokenId))) : "";
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, AccessControl, Royalties)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}