// SPDX-License-Identifier: MIT

/**
████████╗██╗  ██╗███████╗     ██████╗ ██████╗ ███╗   ██╗████████╗██╗███╗   ██╗██╗   ██╗██╗   ██╗███╗   ███╗
╚══██╔══╝██║  ██║██╔════╝    ██╔════╝██╔═══██╗████╗  ██║╚══██╔══╝██║████╗  ██║██║   ██║██║   ██║████╗ ████║
   ██║   ███████║█████╗      ██║     ██║   ██║██╔██╗ ██║   ██║   ██║██╔██╗ ██║██║   ██║██║   ██║██╔████╔██║
   ██║   ██╔══██║██╔══╝      ██║     ██║   ██║██║╚██╗██║   ██║   ██║██║╚██╗██║██║   ██║██║   ██║██║╚██╔╝██║
   ██║   ██║  ██║███████╗    ╚██████╗╚██████╔╝██║ ╚████║   ██║   ██║██║ ╚████║╚██████╔╝╚██████╔╝██║ ╚═╝ ██║
   ╚═╝   ╚═╝  ╚═╝╚══════╝     ╚═════╝ ╚═════╝ ╚═╝  ╚═══╝   ╚═╝   ╚═╝╚═╝  ╚═══╝ ╚═════╝  ╚═════╝ ╚═╝     ╚═╝                                                                                                                                                                
*/

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract CNTNM is Ownable, ERC721A, ReentrancyGuard {
  uint256 internal immutable collectionSize = 999;
  uint256 public immutable maxPerAddressDuringMint = 5;
  string private _baseTokenURI;

  struct SaleConfig {
    uint32 publicSaleStartTime;
    uint64 publicPrice;
  }

  SaleConfig public saleConfig;

  constructor() ERC721A("The Continuum", "CNTNM") {
    _baseTokenURI = "https://cntnm.mypinata.cloud/ipfs/QmdQQ852TDGgMbtmWXykbfBwTmKNg9j6XGjc9K1FKj8Zke/";
  }

  modifier callerIsUser() {
    require(tx.origin == msg.sender, "The caller is another contract");
    _;
  }

  function publicSaleMint(uint256 quantity) external payable callerIsUser {
    require(isPublicSaleOn(saleConfig.publicPrice, saleConfig.publicSaleStartTime),"Public sale has not begun yet");
    require(totalSupply() + quantity <= collectionSize, "Reached max supply");
    require(balanceOf(msg.sender) + quantity <= maxPerAddressDuringMint,"Can not mint this many");
    require(msg.value >= (saleConfig.publicPrice * quantity), "Insufficient funds");
    _safeMint(msg.sender, quantity);
  }

 function setupSaleInfo(uint32 publicSaleStartTime, uint64 publicPriceWei) external onlyOwner {
    saleConfig = SaleConfig(publicSaleStartTime, publicPriceWei);
  }

  function isPublicSaleOn(uint256 publicPriceWei, uint256 publicSaleStartTime) internal view returns (bool) {
    return publicPriceWei != 0 && block.timestamp >= publicSaleStartTime;
  }

  function devMint(uint256 quantity) external onlyOwner {
    _safeMint(msg.sender, quantity);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function setBaseURI(string calldata baseURI) external onlyOwner {
    _baseTokenURI = baseURI;
  }

  function withdraw() external onlyOwner nonReentrant {
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success, "Transfer failed.");
  }

}