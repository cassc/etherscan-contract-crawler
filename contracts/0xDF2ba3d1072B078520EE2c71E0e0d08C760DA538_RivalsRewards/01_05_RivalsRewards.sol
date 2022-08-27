pragma solidity ^0.8.9;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";



contract RivalsRewards is ERC721A, Ownable {
  string public BASE_URI = "https://presalemetadata.mythical.market/rivalsrewards/";
  string public CONTRACT_URI = "https://presalemetadata.mythical.market/rivalsrewards/contractmetadata";

  constructor () ERC721A("NFL Rivals Rewards", "NRR") {}

  function _startTokenId() internal pure override returns (uint256) {
    return 1;
  }

  function setBaseURI(string memory baseURI) external onlyOwner {
    BASE_URI = baseURI;
  }

  function _baseURI() internal view override returns (string memory) {
    return BASE_URI;
  }

  function contractURI() public view returns (string memory) {
    return CONTRACT_URI;
  }

  function setContractURI(string memory _contractURI) external onlyOwner {
    CONTRACT_URI = _contractURI;
  }

  function giveReward(address to, uint256 quantity) external onlyOwner {
    _safeMint(to, quantity);
  }
}