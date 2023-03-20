// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract PixelPresidents is ERC721A, Ownable {
    uint256 WalletMax = 20;
    uint256 Max_Peepo = 5000;
    uint256 public mintPrice = 0.001 ether;
    bool public paused = true;
    string public baseURI = "ipfs://bafybeidxhrp5vy4ab3ehqgxpxnkqukpmyykdz2qli3w2qanfod2zbjtm6q/";
    using Strings for uint256;

    constructor() ERC721A("PixelPresidents", "PxlPrsndts") {}

    function mint(uint256 quantity) external payable {
        require(!paused, "Contract is paused");
        require(quantity + _numberMinted(msg.sender) <= WalletMax, "Limit");
        require(totalSupply() + quantity <= Max_Peepo, "No more Presidents");
        require(msg.value >= (mintPrice * quantity), "More Tax Money!");
        _safeMint(msg.sender, quantity);
    }



    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

    string memory currentBaseURI = baseURI;
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), ".json"))
        : '';
  }
    
    function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

    function setmintPrice(uint256 _mintPrice) public onlyOwner {
        mintPrice = _mintPrice;
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;

    }  

    function withdraw() external payable onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

}