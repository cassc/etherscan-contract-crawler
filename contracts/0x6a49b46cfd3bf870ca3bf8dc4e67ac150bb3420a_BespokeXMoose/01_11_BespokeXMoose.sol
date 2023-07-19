// ) (`-.             _   .-')                               .-')      ('-.   
//  ( OO ).          ( '.( OO )_                            ( OO ).  _(  OO)  
// (_/.  \_)-.        ,--.   ,--.).-'),-----.  .-'),-----. (_)---\_)(,------. 
//  \  `.'  /   .-')  |   `.'   |( OO'  .-.  '( OO'  .-.  '/    _ |  |  .---' 
//   \     /\ _(  OO) |         |/   |  | |  |/   |  | |  |\  :` `.  |  |     
//    \   \ |(,------.|  |'.'|  |\_) |  |\|  |\_) |  |\|  | '..`''.)(|  '--.  
//   .'    \_)'------'|  |   |  |  \ |  | |  |  \ |  | |  |.-._)   \ |  .--'  
//  /  .'.  \         |  |   |  |   `'  '-'  '   `'  '-'  '\       / |  `---. 
// '--'   '--'        `--'   `--'     `-----'      `-----'  `-----'  `------' 

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./UpdatableOperatorFilterer.sol";
import "./RevokableDefaultOperatorFilterer.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
contract BespokeXMoose is ERC721A, RevokableDefaultOperatorFilterer, Ownable {

using Strings for uint256;

  string public baseUri = "https://metadata.mooselands.io/bespoke/";
  uint256 public immutable maxSupply = 100;

  constructor() ERC721A("Bespoke X-Moose", "BXMS") {}

   function bespokeAirdrop(address _to, uint _quantity) public onlyOwner(){
    require(
      totalSupply() + _quantity <= maxSupply,
      "Minting over collection size"
    );
    require(_quantity > 0, "Quantity must be greater than 0");
    _safeMint(_to, _quantity);
  }

  function _startTokenId() internal pure override returns (uint256) {
    return 0;
  }

  function tokenURI(uint256 _tokenId)
  public
  view
  override
  returns (string memory)
  {
    if (!_exists(_tokenId)) revert URIQueryForNonexistentToken();

    return string(abi.encodePacked(baseUri, _tokenId.toString(), ".json"));
  }

  function setBaseUri(string memory _baseUri) public onlyOwner {
    baseUri = _baseUri;
  }


  function withdraw() public onlyOwner {
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }

  function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
    super.setApprovalForAll(operator, approved);
  }

  function approve(address operator, uint256 tokenId) public override payable onlyAllowedOperatorApproval(operator) {
    super.approve(operator, tokenId);
  }

  function transferFrom(address from, address to, uint256 tokenId) public override payable onlyAllowedOperator(from) {
    super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId) public override payable onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
    public
    override
    payable
    onlyAllowedOperator(from)
  {
    super.safeTransferFrom(from, to, tokenId, data);
  }

  function owner() public view virtual override (Ownable, UpdatableOperatorFilterer) returns (address) {
    return Ownable.owner();
  }


}