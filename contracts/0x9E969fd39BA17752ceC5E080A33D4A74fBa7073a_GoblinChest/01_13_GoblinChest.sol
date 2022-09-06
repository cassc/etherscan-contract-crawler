// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract GoblinChest is ERC721, ERC721Enumerable {
    using Strings for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    address private _owner;

    uint256 private _maxSupply;
    uint8 public constant DECIMALS = 18;
    uint256 public constant MINT_PRICE = 49 * (10 ** DECIMALS) / 1000;
    string private _baseTokenURI;
    string private _revealedTokenURI;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Reveal();

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    constructor(uint256 maxSupply, string memory baseTokenURI) ERC721("Goblin Chest", "GCH") {
        _maxSupply = maxSupply;
        _baseTokenURI = baseTokenURI;
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address)
    {
        return _owner;
    }

    function withdraw() public onlyOwner
    {
        payable(_owner).transfer(address(this).balance);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner
    {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function safeMintTo(address to) public onlyOwner returns (uint256)
    {
        return _localSafeMint(to);
    }

    function safeMint() payable public returns (uint256)
    {
        require(msg.value >= MINT_PRICE, "Sent amount is lower then mint price");

        return _localSafeMint(msg.sender);
    }

    function reveal(string memory revealedTokenURI) public onlyOwner
    {
        _revealedTokenURI = revealedTokenURI;

        emit Reveal();
    }

    function maxSupply() public view returns (uint256)
    {
        return _maxSupply;
    }

    function _localSafeMint(address receiver) private returns (uint256)
    {
        require(_tokenIds.current() < _maxSupply, "Max supply reached");

        _tokenIds.increment();

        uint256 newItemId = _tokenIds.current();

        _safeMint(receiver, newItemId);

        return newItemId;
    }

    function _setOwner(address newOwner) private
    {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory)
    {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();

        if (bytes(_revealedTokenURI).length == 0) {
            return baseURI;
        }

        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : "";
    }

    function _baseURI() internal view override(ERC721) returns (string memory)
    {
        return bytes(_revealedTokenURI).length > 0 ? _revealedTokenURI : _baseTokenURI;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721) {
        super._burn(tokenId);
    }
}