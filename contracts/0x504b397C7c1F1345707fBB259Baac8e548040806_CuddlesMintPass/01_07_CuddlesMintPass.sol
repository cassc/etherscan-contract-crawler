pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Strings.sol"; 

contract CuddlesMintPass is Ownable, ERC721A, ReentrancyGuard {

  bool public isSaleOn = false;
  bool public useTokenIdsForBaseURI = false;
  uint256 public maxTotalSupply = 432;
  uint256 public maxPerWallet = 1;
  uint256 public maxPerMint = 1;
  uint256 public weiPrice = 10000000000000000; // .01 ETH
  string public baseURI = "ipfs://QmXKtSnbdnhYmVNSoMKD5H8ZSumRjcd8Ettp14xzPr7CjH";

  constructor() ERC721A("CuddlesMintPass", "CUDDLESMINTPASS") {}

  function mint(uint256 numberOfTokens) external payable {
    require(
      isSaleOn,
      "The mint is not turned on."
    );

    require(
      weiPrice * (numberOfTokens) <= msg.value, 
      "Ether value sent is not correct"
    );

    require(
      numberOfTokens <= maxPerMint,
      "You can only mint a certain amount of NFTs per transaction"
    );

    require(
      balanceOf(msg.sender) + numberOfTokens <= maxPerWallet,
      "You can only mint a certain amount of NFTs per wallet"
    );

    require(
      totalSupply() < maxTotalSupply, 
      "All NFTs have been minted."
    );

    _mint(msg.sender, numberOfTokens);
  }

  function fullfillAddresses(address[] memory addresses, uint8 amountOfNFTs) external onlyOwner {
    for (uint8 i=0; i<addresses.length; i++) {
      _mint(addresses[i], amountOfNFTs);
    }
  }

  function toggleSale() external onlyOwner {
    isSaleOn = !isSaleOn;
  }

  function toggleTokenIds() external onlyOwner {
    useTokenIdsForBaseURI = !useTokenIdsForBaseURI;
  }

  function setBaseURI(string memory newBaseURI) external onlyOwner {
    baseURI = newBaseURI;
  }

  function setMaxPerMint(uint256 newMaxPerMint) external onlyOwner {
    maxPerMint = newMaxPerMint;
  }

  function setMaxPerWallet(uint256 newMaxPerWallet) external onlyOwner {
    maxPerWallet = newMaxPerWallet;
  }

  function setMaxTotalSupply(uint256 newMaxTotalSupply) external onlyOwner {
    maxTotalSupply = newMaxTotalSupply;
  }

  function setSalePrice(uint256 newWeiPrice) external onlyOwner {
    weiPrice = newWeiPrice;
  }

  function withdraw() external onlyOwner {
    payable(msg.sender).transfer(address(this).balance);
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "URI query for nonexistent token");

    if(useTokenIdsForBaseURI) {
      return string(abi.encodePacked(baseURI, Strings.toString(tokenId)));
    } else {
      return baseURI;
    }
  }
}