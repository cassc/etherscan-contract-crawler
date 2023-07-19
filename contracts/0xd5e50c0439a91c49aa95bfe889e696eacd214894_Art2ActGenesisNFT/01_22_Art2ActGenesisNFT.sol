// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import {DefaultOperatorFilterer} from "./royalties/DefaultOperatorFilterer.sol";

contract Art2ActGenesisNFT is
    ERC721,
    ERC721URIStorage,
    Pausable,
    AccessControl,
    ERC721Royalty,
    DefaultOperatorFilterer
{
    using Counters for Counters.Counter;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant CHANGER_ROLE = keccak256("CHANGER_ROLE");
    Counters.Counter private _tokenIdCounter;
    uint16 public maxSupply;

    constructor(address payable treasury) ERC721("Art2ActGeneis", "A2AG") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _setDefaultRoyalty(payable(treasury), 900); //by default 9%
        maxSupply = 2250;
    }

    function setRoyalty(address payable treasury, uint96 feeNumerator) public onlyRole(DEFAULT_ADMIN_ROLE) {
         _setDefaultRoyalty(payable(treasury), feeNumerator); //feeNumerator 100 is 1% and 10000 is 100%
    }

    function setMaxSupply(uint16 max) public onlyRole(DEFAULT_ADMIN_ROLE) {
        maxSupply = max;
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function safeMint(address to, string memory uri)
        public
        onlyRole(MINTER_ROLE)
    {
        uint256 tokenId = _tokenIdCounter.current();
        require(tokenId < maxSupply, "Maximum supply reached!");
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function setTokenURI(uint256 tokenId, string memory uri)
        public
        onlyRole(MINTER_ROLE)
    {
        _setTokenURI(tokenId, uri);
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage, ERC721Royalty)
    {
        super._burn(tokenId);
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
        override(ERC721, AccessControl, ERC721Royalty)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}