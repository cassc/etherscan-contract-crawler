// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

struct PhaseSettings {
  uint64 maxSupply;
  uint64 maxPerWallet;
  uint64 freePerWallet;
  uint256 price;
}

contract BackDoorCasino is ERC721AQueryable, DefaultOperatorFilterer, Ownable, Pausable, ReentrancyGuard {
  string public baseTokenURI;

  address t1 = 0xaE04ea9B67FC32f38D2e614e519f60a967316E3B;

  PhaseSettings public currentPhase;

  constructor(string memory _baseTokenURI) ERC721A("Tripple Oni", "ONI")  {
    setBaseURI(_baseTokenURI);
  }

  function totalMinted() public view returns (uint256) {
    return _totalMinted();
  }

  function numberMinted(address _owner) public view returns (uint256) {
    return _numberMinted(_owner);
  }

  function calculateNonFreeAmount(address _owner, uint256 _amount) public view returns(uint256) {
    uint256 _freeAmountLeft = _numberMinted(_owner) >= currentPhase.freePerWallet ? 0 : currentPhase.freePerWallet - _numberMinted(_owner);

    return _freeAmountLeft >= _amount ? 0 : _amount - _freeAmountLeft;
  }

  function mint(uint256 _amount) public payable whenNotPaused {
    require(_numberMinted(msg.sender) + _amount <= currentPhase.maxPerWallet, "Exceeds maximum tokens at address");
    require(_totalMinted() + _amount <= currentPhase.maxSupply, "Exceeds maximum supply");

    uint256 _nonFreeAmount = calculateNonFreeAmount(msg.sender, _amount);

    require(_nonFreeAmount == 0 || msg.value >= currentPhase.price * _nonFreeAmount, "Ether value sent is not correct");

    _safeMint(msg.sender, _amount);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseTokenURI;
  }

  function setBaseURI(string memory _baseTokenURI) public onlyOwner {
    baseTokenURI = _baseTokenURI;
  }

  function setPhase(
    uint64 _maxSupply,
    uint64 _maxPerWallet,
    uint64 _freePerWallet, 
    uint256 _price
  ) public onlyOwner  {
    currentPhase = PhaseSettings(_maxSupply, _maxPerWallet, _freePerWallet, _price);
  }

  function airdrop(address _address, uint256 _amount) public onlyOwner {
    require(_totalMinted() + _amount <= currentPhase.maxSupply, "Exceeds maximum supply");
    
    _safeMint(_address, _amount);
  }

  function withdraw() external onlyOwner nonReentrant {
    uint256 _balance = address(this).balance;

    require(payable(t1).send(_balance));
  }

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function setApprovalForAll(address operator, bool approved) public override(ERC721A, IERC721A) onlyAllowedOperatorApproval(operator) {
      super.setApprovalForAll(operator, approved);
  }

  function approve(address operator, uint256 tokenId) public payable override(ERC721A, IERC721A) onlyAllowedOperatorApproval(operator) {
      super.approve(operator, tokenId);
  }

  function transferFrom(address from, address to, uint256 tokenId) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
      super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
      super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
      public
      payable
      override(ERC721A, IERC721A)
      onlyAllowedOperator(from)
  {
      super.safeTransferFrom(from, to, tokenId, data);
  }
}