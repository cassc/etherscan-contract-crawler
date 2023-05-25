// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract ChampionsAscensionElemental is ERC721, Pausable, AccessControl, ERC721Burnable {
    using Counters for Counters.Counter;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant MINT_ADMIN_ROLE = keccak256("MINT_ADMIN_ROLE");

    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _burnedCounter;
    uint256 public mintLimit; // maximum total number minted

    constructor() ERC721("ChampionsAscensionElemental", "ELEMENTAL") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(MINT_ADMIN_ROLE, msg.sender);

        mintLimit = 10000;
    }

    function _baseURI() internal pure override returns (string memory) {
        return "https://champions.io/elementals/nfts/";
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /// @notice the total number minted
    function totalMinted() public view returns(uint256) {
        return _tokenIdCounter.current();
    }

    /// @notice the current supply: number minted less the number burned
    function totalSupply() external view returns(uint256) {
        return _tokenIdCounter.current() - _burnedCounter.current();
    }

    /// @dev this function is private so it does not check caller permissions
    /// @dev it does enforce limit on the total number minted
    /// @dev first token ID is 1
    function _mintOne(address to) private whenNotPaused {
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        require(tokenId <= mintLimit, "mint limit exceeded");
        _safeMint(to, tokenId);
    }

    function mint(address to, uint32 _number) public onlyRole(MINTER_ROLE) {
        require(0 < _number, "number to mint must be positive");
        for (uint32 i = 0; i < _number; ++i) {
            _mintOne(to);
        }
    }

    function setMintLimit(uint256 limit) public onlyRole(MINT_ADMIN_ROLE) {
        mintLimit = limit;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
        if (to == address(0)) {
            _burnedCounter.increment();
        }
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}