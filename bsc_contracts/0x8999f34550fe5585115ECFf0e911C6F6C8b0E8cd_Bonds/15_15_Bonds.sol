// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract Bonds is ERC721, ERC721Burnable, AccessControl {
    using EnumerableSet for EnumerableSet.UintSet;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    uint256 private _tokenId;
    mapping(address => EnumerableSet.UintSet) ownedTokens;

    constructor() ERC721("M-DAO Bonds", "M-Bonds") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override {
        ownedTokens[from].remove(tokenId);
        ownedTokens[to].add(tokenId);
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function mint(address to) public onlyRole(MINTER_ROLE) returns (uint256 tokenId) {
        tokenId = _tokenId;
        _tokenId++;
        _safeMint(to, tokenId);
    }

    function getTokenIds(
        address owner,
        uint256 offset,
        uint256 size
    ) public view returns (uint256[] memory tokenIds) {
        require(offset + size <= balanceOf(owner), "out of bounds");
        uint256[] memory ids = ownedTokens[owner].values();
        tokenIds = new uint256[](size);
        for (uint256 i = 0; i < size; i++) {
            tokenIds[i] = ids[offset + i];
        }
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}