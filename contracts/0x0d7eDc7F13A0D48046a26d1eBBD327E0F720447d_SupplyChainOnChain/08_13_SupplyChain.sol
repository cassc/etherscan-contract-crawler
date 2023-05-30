// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "erc721a/contracts/ERC721A.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./IQR.sol";

contract SupplyChainOnChain is ERC721A, Ownable, ReentrancyGuard, DefaultOperatorFilterer{
  address[][1111] public holders;
  uint256 public maxSupply = 1111;
  uint256 public MAX_MINTS_PER_WALLET = 5;
  uint256 public mintPrice = 0.002 ether;
  address public QRAdress;

  constructor(
  ) ERC721A("SupplyChainOnChain", "SC") {
  }

  function mint(uint256 quantity) external payable{
    require(totalSupply() + quantity <= maxSupply, "OOS!");
    require(_numberMinted(msg.sender) + quantity <= MAX_MINTS_PER_WALLET, "Max 5 mint per wallet!");
    require(quantity * mintPrice <= msg.value, "Funds not enough.");
    _safeMint(msg.sender, quantity);
  }
  function withdraw() external onlyOwner{
      (bool success, ) = msg.sender.call{value: address(this).balance}("");
      require(success, "Transfer failed.");
  }
  function setMaxSupply(uint256 _maxSupply) external onlyOwner{
      require(_maxSupply < maxSupply, "Only reduced supply.");
      maxSupply = _maxSupply;
  }

/////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////// DATA URI //////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////
  function addTrait(string memory traitType, string memory value, bool end) internal pure returns (string memory property){
      return string.concat(
          '{"trait_type":"',
          traitType,
          '","value":"',
          value,
          '"}',
          end? "": ","
      );
  }

  function getProperties(uint256 tokenId) internal view returns(string memory properties){
      for (uint256 i=0; i<holders[tokenId].length; ++i){
          properties = string.concat(properties, 
                                     addTrait(Strings.toString(i+1),
                                              Strings.toHexString(uint160(holders[tokenId][i]), 20),
                                              i == holders[tokenId].length - 1
                                             )
                                    );
      }
  }
/////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////// IMAGE GEN /////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////
  function drawHorizontal(uint8[][] memory graph, uint256 x1, uint256 x2, uint256 y) internal pure returns(string memory horizontal){
      if (x1 == x2){
          horizontal = "";
      }
      else if (x2 == x1 + 1){
          if (graph[y][x1]%2 == 1){
          horizontal = string.concat('M', 
                                     Strings.toString(x1), 
                                     ' ',
                                     Strings.toString(y),
                                     ' h1v1h-1z '
                                    );
          }
          else{
              horizontal = "";
          }
      }
      else{
          horizontal = string.concat(drawHorizontal(graph, x1, (x1+x2)/2, y), drawHorizontal(graph, (x1+x2)/2, x2, y));
      }
  }
  function drawVertical(uint8[][] memory graph, uint256 size, uint256 y1, uint256 y2) internal pure returns(string memory vertical){
      if (y1 == y2){
          vertical = "";
      }
      else if (y2 == y1 + 1){
          vertical = drawHorizontal(graph, 0, size, y1);
      }
      else{
          vertical = string.concat(drawVertical(graph, size, y1, (y1+y2)/2), drawVertical(graph, size, (y1+y2)/2, y2));
      }
  }

  function randomHue(uint256 tokenId, string memory key) internal pure returns(uint256 hue){
      hue = uint256(keccak256(abi.encodePacked(key, tokenId))) % 360;
  }

  function getColor(uint256 tokenId, bool isDark) internal pure returns(string memory color){
      color = !isDark? string.concat(
          "hsl(",
          Strings.toString(randomHue(tokenId, "first")),
          ",39%,77%)"
      ): string.concat(
          "hsl(",
          Strings.toString(randomHue(tokenId, "second")),
          ",39%,23%)");
  }

  function drawString(uint8[][] memory graph, uint256 tokenId) internal pure returns(string memory svg){
      svg = string.concat('<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="-4 -4 45 45"> <style>.a {fill: url(#A);}</style><defs><pattern id="A" width="1" height="1" patternUnits="userSpaceOnUse"><rect width="1" height="1" fill="',
                          getColor(tokenId, true),
                          '"/></pattern></defs><rect x="-4" y="-4" width="45" height="45" fill="',
                          getColor(tokenId, false),
                          '"/><path class="a" d="',
                          drawVertical(graph, 37, 0, 37),
                          '"/></svg>'
                          );
      svg = string.concat("data:image/svg+xml;base64,", Base64.encode(bytes(svg)));
  }

  function getImage(uint256 tokenId) internal view returns (string memory image){
      string memory content = holders[tokenId].length == 0? string.concat("#", Strings.toString(tokenId), " has never been transferred before."):
          string.concat(
              "#",
              Strings.toString(tokenId),
              " has been transferred ",
              Strings.toString(holders[tokenId].length),
              " times, last holder was ",
              Strings.toHexString(uint160(holders[tokenId][holders[tokenId].length - 1]), 20),
              "."
          );
      // IQR draw
      uint8[][] memory graph = IQRCode(QRAdress).initQR(content, ErrorCorrectionLevel.LOW, 5);
      image = drawString(graph, tokenId);
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns(string memory){
      require(totalSupply() > _tokenId, "Out of index");
      string memory _name = string(abi.encodePacked("Merchandise #", Strings.toString(_tokenId)));
      string memory _description = "Scan it to trace your bag!";
      return string.concat(
          "data:application/json;base64,",
          Base64.encode(
              abi.encodePacked(
                  '{"name":"', _name,
                  '", "description": "', _description,
                  '", "attributes": [', getProperties(_tokenId),
                  '], "image":"', getImage(_tokenId),
                  '"}'
              )
          )
      );
  }

  function setQRAdress(address QRAdress_) external onlyOwner{
      QRAdress = QRAdress_;
  }

  function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
      super.setApprovalForAll(operator, approved);
  }
  
  function approve(address operator, uint256 tokenId) public override payable onlyAllowedOperatorApproval(operator) {
      super.approve(operator, tokenId);
  }

  function transferFrom(address from, address to, uint256 tokenId) public override payable onlyAllowedOperator(from){
      holders[tokenId].push(from);
      super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId) public override payable onlyAllowedOperator(from) {
      super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override payable onlyAllowedOperator(from){
      super.safeTransferFrom(from, to, tokenId, data);
  }
}