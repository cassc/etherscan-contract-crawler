// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "ERC721.sol";
import "ERC721URIStorage.sol";
import "ERC721Burnable.sol";
import "ERC2981.sol";
import "AccessControl.sol";
import "Pausable.sol";
import "Counters.sol";

/// @custom:security-contact [email protected]
contract ZelosCollectible is
    ERC721,
    ERC721URIStorage,
    ERC721Burnable,
    ERC2981,
    AccessControl,
    Pausable
{
    using Counters for Counters.Counter;
    string private _contractURI;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    Counters.Counter private _tokenIdCounter;

    constructor() ERC721("Zelos Collectibles - Pioneer Series", "ZCPS") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _setDefaultRoyalty(msg.sender, 750);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function mint(address to, string memory uri)
        public
        onlyRole(MINTER_ROLE)
        returns (uint256)
    {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
        return tokenId;
    }

    function mint(
        address to,
        string memory uri,
        address royaltyReceiver,
        uint96 feeNumerator
    ) public onlyRole(MINTER_ROLE) returns (uint256) {
        uint256 tokenId = mint(to, uri);
        _setTokenRoyalty(tokenId, royaltyReceiver, feeNumerator);
        return tokenId;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
        _resetTokenRoyalty(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, AccessControl, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function setContractURI(string calldata __contractURI)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _contractURI = __contractURI;
    }
}