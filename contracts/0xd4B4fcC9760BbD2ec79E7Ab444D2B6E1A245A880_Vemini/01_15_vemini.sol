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
    bool public isSaleActive = false;
    bool public isPreSaleActive = false;
    string public baseTokenURI = "https://service.vemini.io/api/get_metadata_vemini/";

    constructor() ERC721("Vemini Token", "VEMINI") {}

    function mintForMarketing(address to, uint256 amount) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        require(tokenId + amount <= MAX_SUPPLY, "Sorry we reached the cap");

        for (uint i = 0; i < amount; i++) {
            tokenId = _tokenIdCounter.current();
            _safeMint(to, tokenId);
            uint256 next = tokenId + 1;
            _setTokenURI(tokenId, string(abi.encodePacked(baseTokenURI, Strings.toString(next))));
            _tokenIdCounter.increment();
        }
    }

    function safeMint() public {
        uint256 tokenId = _tokenIdCounter.current();
        require(balanceOf(msg.sender) == 0, "We have a limit of 1 NFT per wallet");
        require(tokenId + 1 <= MAX_SUPPLY, "Sorry we reached the cap");
        require(isSaleActive, "Mint have not started yet" );

        _safeMint(msg.sender, tokenId);
        uint256 next = tokenId + 1;
        _setTokenURI(tokenId, string(abi.encodePacked(baseTokenURI, Strings.toString(next))));
        _tokenIdCounter.increment();

    }


    function flipSaleStatus() public onlyOwner {
        isSaleActive = !isSaleActive;
    }

    function flipPreSaleStatus() public onlyOwner {
        isPreSaleActive = !isPreSaleActive;
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