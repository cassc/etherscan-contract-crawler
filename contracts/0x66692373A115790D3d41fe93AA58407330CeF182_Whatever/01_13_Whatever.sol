// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract Whatever is ERC721, ERC721Enumerable, Ownable {
    string private _baseTokenURI;
    bool public isSaleActive = false;

    uint256 public constant MINT_PRICE = 0.01 ether;

    uint256 public immutable maxSupply;

    constructor(uint256 maxSupply_) ERC721("Whatever", "WHATEVER") {
        maxSupply = maxSupply_;
    }

    function setBaseURI(string memory _uri) public onlyOwner {
        _baseTokenURI = _uri;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setSaleActiveState(bool isActive) external onlyOwner {
        isSaleActive = isActive;
    }

    function devMint(address to) external onlyOwner {
        uint256 ts = totalSupply();

        require(ts + 1 <= maxSupply, "Purchase would exceed max tokens");

        _safeMint(to, ts);
    }

    function mint() public payable {
        uint256 ts = totalSupply();

        require(isSaleActive, "Public sale is unavailable");
        require(ts + 1 <= maxSupply, "Purchase would exceed max tokens");
        require(MINT_PRICE <= msg.value, "Ether value sent is incorrect");

        _safeMint(msg.sender, ts);
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}