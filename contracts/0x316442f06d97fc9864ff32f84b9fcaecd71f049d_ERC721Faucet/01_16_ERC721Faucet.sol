// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract ERC721Faucet is ERC721Enumerable, ERC721URIStorage, AccessControl {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    string _baseTokenURI;

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    constructor() ERC721("Reddio", "RED") {
        _tokenIds.increment();
        _setupRole(ADMIN_ROLE, msg.sender);
        _baseTokenURI = "https://metadata.reddio.com/api/tokens/";
    }

    function mint(address to) public returns (uint256) {
        uint256 newItemId = _tokenIds.current();
        _mint(to, newItemId);

        _tokenIds.increment();
        return newItemId;
    }

    function mint_multi(address to, uint256 amount) public returns (uint256) {
        for (uint i = 0; i < amount; i++) {
            uint256 newItemId = _tokenIds.current();
            _mint(to, newItemId);
            _tokenIds.increment();
        }
        return amount;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }


    function setBaseURI(string memory baseURI) public {
        require(
            hasRole(ADMIN_ROLE, _msgSender()),
            "ReddioGeneral721: must have admin role"
        );
        _baseTokenURI = baseURI;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
    internal
    override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
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
    override(ERC721, ERC721Enumerable, AccessControl)
    returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}