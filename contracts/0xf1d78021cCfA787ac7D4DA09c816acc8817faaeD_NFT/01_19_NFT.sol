// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract NFT is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable {

    using SafeERC20 for IERC20;
    using Counters for Counters.Counter;
    Counters.Counter private currentTokenId;
    IERC20 private immutable usdt;

    mapping (string => uint) public prices;
    address public cashAddress;

    constructor(address _usdt, address _cashAddress) ERC721("ProfitOnWeed", "GGP") {
        usdt = IERC20(_usdt);
        cashAddress = _cashAddress;
    }

    function setCashAddress(address _address) public onlyOwner {
        cashAddress = _address;
    }

    function setNewPrice(string memory _category, uint256 _price) public onlyOwner {
        require(_price > 0, "Price must be more 0!");

        prices[_category] = _price;
    }

     function removePrice(string memory _category) public onlyOwner {
        delete prices[_category];
    }

    function mintOwner(address recipient, string memory uri) public onlyOwner returns (uint256) {
        uint256 tokenId = currentTokenId.current();

        currentTokenId.increment();
        _safeMint(recipient, tokenId);
        _setTokenURI(tokenId, uri);
        return tokenId;
    }

    function mintNFT(address recipient, string memory uri, string memory _category) public returns (uint256) {
        uint256 tokenId = currentTokenId.current();
        require(prices[_category] > 0, "Not found category!");

        usdt.safeTransferFrom(msg.sender, cashAddress, prices[_category]);
        currentTokenId.increment();
        _mint(recipient, tokenId);
        _setTokenURI(tokenId, uri);
        return tokenId;
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
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
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}