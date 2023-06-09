// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract MGSpaceship is ERC721Enumerable, Ownable, AccessControl {
    using Counters for Counters.Counter;

    string public _baseTokenURI;
    uint256 public constant MAX_SUPPLY = 10000;
    Counters.Counter private _tokenIdTracker;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _tokenIdTracker = Counters.Counter({_value: 1});
    }

    function mint(address receiver) external returns(uint256) {
        require(hasRole(MINTER_ROLE, msg.sender), "Do not have mint role");
        require(totalSupply() < MAX_SUPPLY, "Mint over");
        
        uint256 tokenId = _tokenIdTracker.current();
        _mint(receiver, tokenId);
        _tokenIdTracker.increment();
        return tokenId;
    }

    function tokenOfOwnerAll(address user) public view returns (uint256[] memory) {
        uint256 bal = balanceOf(user);
        uint256[] memory tokenList = new uint256[](bal);
        
        for (uint i; i < bal; i++) {
            tokenList[i] = tokenOfOwnerByIndex(user, i);
        }
        
        return tokenList;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override (AccessControl, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory newBaseURI) external onlyOwner() {
        _baseTokenURI = newBaseURI;
    }
}