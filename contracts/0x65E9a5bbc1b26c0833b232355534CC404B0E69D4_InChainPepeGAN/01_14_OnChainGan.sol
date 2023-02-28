// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;
import "erc721a/contracts/ERC721A.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./renderer.sol";

contract InChainPepeGAN is DefaultOperatorFilterer, ERC721A, ReentrancyGuard, Ownable, Renderer{
    uint256 public TEAM_RESERVED=100;
    uint256 public MAX_COLLECTION_SIZE=999;
    uint256 public MINT_PRICE = 0.0069 ether;
    bool public DEV_MINTED = false;
    uint256[1100] randomSeeds; // Just in case the dev mint was done after the whole public.

  constructor() ERC721A("InChainPepeGAN", "PepeGAN") {
  }

  function mint() external payable{
      uint256 supply = totalSupply();
      require(supply + 1 <= MAX_COLLECTION_SIZE, "Reached max supply");
      require(_numberMinted(msg.sender) == 0, "Max 1 mint per wallet!");
      require(msg.value >= MINT_PRICE, "Mint price: 0.0069 eth");
      _safeMint(msg.sender, 1);
  }
  function devMint() external onlyOwner{
      require(!DEV_MINTED, "Dev minted!");
      _safeMint(msg.sender, 100);
      DEV_MINTED = true;
  }
  function changeRandomSeeds(uint256 tokenId) public{
      require(ownerOf(tokenId) == msg.sender, "Not the owner");
      randomSeeds[tokenId] += 2000;
  }

  function tokenURI(uint256 tokenId) public view override returns (string memory){
      string memory _name = string(abi.encodePacked("GANPepe #", Strings.toString(tokenId)));
      string memory _description = "New way to put art in chain.";
      if (randomSeeds[tokenId] > 0){
          tokenId = randomSeeds[tokenId];
      }
      Seeds memory seeds = getSeeds(tokenId);
      string memory gif = getGIF(seeds);
      string memory animatedURI = getAnimatedURI(gif);
      return string(
          abi.encodePacked(
              "data:application/json;base64,",
              Base64.encode(
                  bytes(
                      abi.encodePacked(
                          '{"name":"', _name,
                          '", "description": "', _description,
                          '", "attributes": [', getProperty(seeds),
                          '], "image":"', gif, 
                          '", "animation_url":"', animatedURI,
                          '"}'
                      )
                  )
              )
          )
      );
  }
  function withdraw() external onlyOwner{
      (bool success, ) = msg.sender.call{value: address(this).balance}("");
      require(success, "Transfer failed.");
  }

  function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
      super.setApprovalForAll(operator, approved);
  }
  
  function approve(address operator, uint256 tokenId) public override payable onlyAllowedOperatorApproval(operator) {
      super.approve(operator, tokenId);

  }

  function transferFrom(address from, address to, uint256 tokenId) public override payable onlyAllowedOperator(from){
      super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId) public override payable onlyAllowedOperator(from) {
      super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override payable onlyAllowedOperator(from){
      super.safeTransferFrom(from, to, tokenId, data);
  }
}