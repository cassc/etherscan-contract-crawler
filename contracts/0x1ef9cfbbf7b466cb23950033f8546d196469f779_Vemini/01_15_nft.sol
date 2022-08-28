// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/// @custom:security-contact [email protected]
contract Vemini is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    uint256 public MAX_SUPPLY = 10000;
    uint256 public mintPrice = 80000000000000000;
    bool public isSaleActive = false;
    bool public isPreSaleActive = false;
    string public baseTokenURI = "https://service.vemini.io/api/get_metadata/";

    constructor() ERC721("Vemini", "VEMNI") {}

    function safeMint(address to, uint256 amount) public payable {
        uint256 tokenId = _tokenIdCounter.current();
        require(isSaleActive, "Mint have not started yet" );
        require(amount <= 25, "Up to 25 NFTs allowed");
        require(tokenId + amount <= MAX_SUPPLY, "Sorry we reached the cap");
        require(msg.value >= mintPrice * amount, "Not enough ETH sent");

        for (uint i = 0; i < amount; i++) {
            tokenId = _tokenIdCounter.current();
            _safeMint(to, tokenId);
            uint256 next = tokenId + 1;
            _setTokenURI(tokenId, string(abi.encodePacked(baseTokenURI, Strings.toString(next))));
            _tokenIdCounter.increment();
        }
    }


    function flipSaleStatus() public onlyOwner {
        isSaleActive = !isSaleActive;
    }

    function flipPreSaleStatus() public onlyOwner {
        isPreSaleActive = !isPreSaleActive;
    }

    function setMintPrice(uint256 price) public onlyOwner {
        mintPrice = price;
    }

    function checkPrice() public view returns (uint256){
        return mintPrice;
    }

    function getBalance() public view returns(uint) {
        return address(this).balance;
    }

    function withdrawFees() public onlyOwner {
        address payable to = payable(msg.sender);
        to.transfer(getBalance());
    }

    function checkSaleStatus() public view returns (bool){
        return isSaleActive;
    }

    function checkCurrentMinting() public view returns (uint256){
        return _tokenIdCounter.current();
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
    override(ERC721, ERC721Enumerable)
    returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}