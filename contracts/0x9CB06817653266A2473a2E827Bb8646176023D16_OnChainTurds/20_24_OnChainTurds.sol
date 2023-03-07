// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

interface IRenderer {
  function tokenURI(uint256 tokenId, uint256 seed) external view returns (string memory);
}

contract OnChainTurds is 
  Ownable,
  ERC721Burnable,
  ERC721Enumerable,
  ERC721Pausable,
  ERC721Royalty,
  DefaultOperatorFilterer
  {

  event SeedUpdated(uint256 indexed tokenId, uint256 seed);

  using Strings for uint256;

  uint256 private _tokenId = 1;

  address public renderer;

  uint256 public maxSupply = 10000;

  uint256 public MAX_MINT = 25;

  bool public canUpdateSeed = true;

  // tokenId => seed
  mapping(uint256 => uint256) public seeds;

  bool public useOperatorFilter = true;


  modifier onlyAllowedOperator(address from) virtual override {
    // Allow spending tokens from addresses with balance
    // Note that this still allows listings and marketplaces with escrow to transfer tokens if transferred
    // from an EOA.
    if (from != msg.sender && useOperatorFilter) {
      _checkFilterOperator(msg.sender);
    }
    _;
  }

  modifier onlyAllowedOperatorApproval(address operator) virtual override {
    if(useOperatorFilter) {
      _checkFilterOperator(operator);
    }
    _;
  }

  constructor() ERC721("turds-wtf", "TURD") { 
    _setDefaultRoyalty(owner(), 750);
    _pause();
  }

  // ##########  ADMIN FUNCTIONS ############

  function setRenderer(address _renderer) public onlyOwner {
    renderer = _renderer;
  }

  function setPaused(bool _paused) public onlyOwner {
    if(_paused) {
      _pause();
    } else {
      _unpause();
    }
  }

  function updateSeed(uint256 tokenId, uint256 seed) external onlyOwner {
    require(canUpdateSeed, "Cannot set the seed");
    seeds[tokenId] = seed;
    emit SeedUpdated(tokenId, seed);
  }

  function disableSeedUpdate() external onlyOwner {
    canUpdateSeed = false;
  }

  function setDefaultRoyalty(address receiver, uint96 feeNumerator) onlyOwner public {
    _setDefaultRoyalty(receiver, feeNumerator);
  }

  function setTokenRoyalty(uint256 tokenId, address receiver, uint96 feeNumerator) onlyOwner public {
    _setTokenRoyalty(tokenId, receiver, feeNumerator);
  }

  function setOperatorFilter(bool isActive) onlyOwner public {
    useOperatorFilter = isActive;
  }

  // ##########  PUBLIC FUNCTIONS ############

  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    _requireMinted(tokenId);
    return IRenderer(renderer).tokenURI(tokenId, seeds[tokenId]);
  }

  function _mintTurd() internal {
    uint256 pseudoRandomness = random(_tokenId);
    seeds[_tokenId] = pseudoRandomness;
    _mint(msg.sender, _tokenId);
    _tokenId++;
  }

  function mint(uint count) public {
    require(!paused(), "Minting is paused");
    require(count <= MAX_MINT, "Exceeds max per transaction.");
    require(_tokenId + count <= maxSupply, "Exceeds max supply.");
    for (uint32 i = 0; i < count; i++) {
      _mintTurd();
    }
  }

  function _burn(uint256 tokenId) internal virtual override(
      ERC721,
      ERC721Royalty
  ) {
      delete seeds[tokenId];
      super._burn(tokenId);
  }

  function random(uint256 tokenId) private view returns (uint256 pseudoRandomness) {
    pseudoRandomness = uint256(
      keccak256(abi.encodePacked(blockhash(block.number - 1), tokenId))
    );
    return pseudoRandomness;
  }

  function withdraw() external payable onlyOwner {
    (bool os,) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }


  function setApprovalForAll(address operator, bool approved) public override(IERC721, ERC721) onlyAllowedOperatorApproval(operator) {
      super.setApprovalForAll(operator, approved);
  }

  function approve(address operator, uint256 tokenId) public override(IERC721, ERC721) onlyAllowedOperatorApproval(operator) {
      super.approve(operator, tokenId);
  }

  function transferFrom(address from, address to, uint256 tokenId) public override(IERC721, ERC721) onlyAllowedOperator(from) {
      super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId) public override(IERC721, ERC721) onlyAllowedOperator(from) {
      super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
      public
      override(IERC721, ERC721)
      onlyAllowedOperator(from)
  {
      super.safeTransferFrom(from, to, tokenId, data);
  }

  function _beforeTokenTransfer(
      address from,
      address to,
      uint256 tokenId,
      uint256 batchSize
  ) internal virtual override(ERC721, ERC721Enumerable, ERC721Pausable) {
    super._beforeTokenTransfer(from, to, tokenId, batchSize);
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override (
      ERC721, 
      ERC721Enumerable,
      ERC721Royalty
    )
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  } 

}