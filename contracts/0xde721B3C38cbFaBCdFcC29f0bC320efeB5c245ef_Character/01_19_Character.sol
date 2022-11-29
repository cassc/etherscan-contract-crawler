// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./operator-filter-registry/DefaultOperatorFilterer.sol";

/// @title Character contract
/// @custom:juice 100%
/// @custom:security-contact [email protected]
contract Character is ERC721, ERC721Burnable, Pausable, Ownable, AccessControl, DefaultOperatorFilterer {
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant AIRDROP_ROLE = keccak256("AIRDROP_ROLE");

    using Counters for Counters.Counter;

    string public baseURI;
    uint256 public maxSupply;
    mapping (address => bool) private airdrops;

    Counters.Counter private tokenIdCounter;

    constructor(string memory baseURI_, uint256 maxSupply_)
        ERC721("Character", "CHAR")
    {
        baseURI = baseURI_;
        maxSupply = maxSupply_;

        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(MANAGER_ROLE, _msgSender());
        _grantRole(AIRDROP_ROLE, _msgSender());
    }

    function claimAirdrop(address recipient)
        external
        whenNotPaused
        onlyRole (AIRDROP_ROLE)
    {
        require(tokenIdCounter.current() < maxSupply, "Character: exceeds max supply");
        require(airdrops[recipient] == false, "Character: exceeds airdrop limit");

        airdrops[recipient] = true;

        uint256 tokenId = tokenIdCounter.current();
        tokenIdCounter.increment();
        _safeMint(recipient, tokenId);
    }

    function airdrop(address[] calldata recipients)
        external
        whenNotPaused
        onlyRole (MANAGER_ROLE) 
    {
        require(tokenIdCounter.current() + recipients.length <= maxSupply, "Character: exceeds max supply");
    
        for (uint256 i = 0; i < recipients.length; i++)
        {
            uint256 tokenId = tokenIdCounter.current();
            tokenIdCounter.increment();
            _mint(recipients[i], tokenId);
        }
    }

    function pause()
        external
        onlyRole (MANAGER_ROLE)
    {
        _pause();
    }

    function unpause()
        external
        onlyRole (MANAGER_ROLE)
    {
        _unpause();
    }

    function setBaseURI(string calldata baseURI_)
        external
        onlyRole (MANAGER_ROLE)
    {
        baseURI = baseURI_;
    }

    function transferFrom(address from, address to, uint256 tokenId)
        public
        override
        onlyAllowedOperator(from)
    {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override (ERC721, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _baseURI()
        internal
        view
        override
        returns (string memory)
    {
        return baseURI;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }
}