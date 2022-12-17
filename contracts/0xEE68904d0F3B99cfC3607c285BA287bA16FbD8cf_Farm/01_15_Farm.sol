// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract Farm is ERC721Enumerable, AccessControl {
    using Counters for Counters.Counter;
    using Strings for uint256;

    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    
    string public baseURI;
    Counters.Counter private tokenIdCounter;

    constructor() ERC721("Bad Bunnies Farm", "BBFA") {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(OWNER_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
    }

    // views

    function _baseURI() internal view override(ERC721) returns(string memory) {
        return baseURI;
    }

    // minter

    function mint(address to, uint256 qty) public onlyMinter {
        for (uint256 i = 0; i < qty; i++) {
            tokenIdCounter.increment();
            uint256 tokenId = tokenIdCounter.current();
            _safeMint(to, tokenId);
        }
    }

    function burn(uint256 tokenId) public virtual {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId) || hasRole(MINTER_ROLE, _msgSender()),
            "ERC721: caller is not token owner or approved"
        );
        _burn(tokenId);
    }

    // owner

    function setBaseURI(string memory _URI) external onlyOwner {
        baseURI = _URI;
    }

    // misc

    modifier onlyMinter() {
        require(hasRole(MINTER_ROLE, _msgSender()), "Only minter");
        _;
    }

    modifier onlyOwner() {
        require(hasRole(OWNER_ROLE, _msgSender()), "Only owner");
        _;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable, AccessControl) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId ||
            interfaceId == type(IAccessControl).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}