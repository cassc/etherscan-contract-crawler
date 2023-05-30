// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/// @title IslandG1 contract
/// @custom:juice 100%
/// @custom:security-contact [email protected]
contract IslandG1 is ERC721, ERC721Burnable, Pausable, Ownable, AccessControl {
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant AIRDROP_ROLE = keccak256("AIRDROP_ROLE");

    using Counters for Counters.Counter;

    string public baseURI;
    uint256 public maxSupply;
    uint256 public publicMint;
    bool public publicMintEnabled;
    mapping (address => bool) private minters;
    mapping (address => bool) private airdrops;

    Counters.Counter private tokenIdCounter;

    constructor()
        ERC721("IslandG1", "ISLANDG1")
    {
        baseURI = "https://castaways.com/";
        maxSupply = 500;
        publicMint = 100;
        publicMintEnabled = false;

        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(MANAGER_ROLE, _msgSender());
        _grantRole(AIRDROP_ROLE, _msgSender());
    }

    // F2O
    function mintIsland()
        public
        whenNotPaused
    {
        require(tokenIdCounter.current() < maxSupply, "IslandG1: exceeds max supply");
        require(balanceOf(_msgSender()) == 0, "IslandG1: exceeds mint limit");
        require(minters[_msgSender()] == false, "IslandG1: exceeds mint limit");
        require(publicMintEnabled == true, "IslandG1: public mint not enabled");
        require(publicMint > 0, "IslandG1: no public mint allocation");
        require(tx.origin == _msgSender(), "IslandG1: invalid eoa");
        
        minters[_msgSender()] = true;

        publicMint -= 1;

        uint256 tokenId = tokenIdCounter.current();
        tokenIdCounter.increment();
        _safeMint(_msgSender(), tokenId);
    }

    // big fish
    function claimAirdrop(address _recipient)
        public
        whenNotPaused
        onlyRole (AIRDROP_ROLE)
    {
        require(tokenIdCounter.current() < maxSupply, "IslandG1: exceeds max supply");
        require(airdrops[_recipient] == false, "IslandG1: exceeds airdrop limit");
        require(publicMintEnabled == true, "IslandG1: public mint not enabled");

        airdrops[_recipient] = true;

        uint256 tokenId = tokenIdCounter.current();
        tokenIdCounter.increment();
        _safeMint(_recipient, tokenId);
    }

    function airdrop(address _recipient, uint256 amount)
        public
        whenNotPaused
        onlyRole (MANAGER_ROLE)
    {
        require(tokenIdCounter.current() + amount <= maxSupply, "IslandG1: exceeds max supply");

        for (uint256 i = 0; i < amount; i++)
        {
            uint256 tokenId = tokenIdCounter.current();
            tokenIdCounter.increment();
            _mint(_recipient, tokenId);
        }
    }

    function airdropHolders(address[] calldata recipients)
        public
        whenNotPaused
        onlyRole (MANAGER_ROLE) 
    {
        require(tokenIdCounter.current() + recipients.length <= maxSupply, "IslandG1: exceeds max supply");
    
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

    function setPublicMintEnabled(bool enabled)
        public
        onlyRole (MANAGER_ROLE)
    {
        publicMintEnabled = enabled;
    }

    function setBaseURI(string calldata baseURI_)
        public
        onlyRole (MANAGER_ROLE)
    {
        baseURI = baseURI_;
    }

    function totalSupply()
        public
        view
        returns (uint256)
    {
        return tokenIdCounter.current();
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

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override (ERC721, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}