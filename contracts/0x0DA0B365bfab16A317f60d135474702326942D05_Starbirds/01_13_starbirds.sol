// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract Starbirds is ERC721, ERC721Enumerable, Ownable {
    bool public saleIsActive = false;
    bool public freeMintActive = true;
    string private _baseURIextended;
    uint256 public MAX_SUPPLY = 2000;
    uint256 public PRICE_PER_TOKEN = 0.04 ether;

    constructor() ERC721("Starbirds", "STARBIRD") {
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function setBaseURI(string memory baseURI_) external onlyOwner() {
        _baseURIextended = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function reserve(uint256 n) public onlyOwner {
      uint supply = totalSupply();
      uint i;
      for (i = 0; i < n; i++) {
          _safeMint(msg.sender, supply + i);
      }
    }

    function setSaleState(bool newState) public onlyOwner {
        saleIsActive = newState;
    }

    function setFreeMintState(bool newState) public onlyOwner {
        freeMintActive = newState;
    }

    function setPrices(uint256 pPublic) public onlyOwner {
        require(pPublic >= 0, "Prices should be higher or equal than zero.");
        PRICE_PER_TOKEN = pPublic;
    }

    function setLimits(uint256 mSupply) public onlyOwner {
        require(mSupply >= totalSupply(), "MAX_SUPPLY should be higher or equal than total supply.");
        MAX_SUPPLY = mSupply;
    }

    function mint(uint numberOfTokens) public payable {
        uint256 ts = totalSupply();
        require(saleIsActive, "Sale must be active to mint tokens");
        require(ts + numberOfTokens <= MAX_SUPPLY, "Purchase would exceed max tokens");
        if (!freeMintActive) {
            require(PRICE_PER_TOKEN * numberOfTokens <= msg.value, "Ether value sent is not correct");
        }

        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, ts + i);
        }
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}