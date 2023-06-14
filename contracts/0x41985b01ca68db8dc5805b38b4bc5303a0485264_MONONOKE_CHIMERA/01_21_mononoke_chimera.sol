//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/token/common/ERC2981.sol';
import 'erc721psi/contracts/ERC721Psi.sol';
import 'operator-filter-registry/src/DefaultOperatorFilterer.sol';

contract MONONOKE_CHIMERA is
  ERC721Psi,
  ERC2981,
  Ownable,
  ReentrancyGuard,
  DefaultOperatorFilterer
{
  using Strings for uint256;

  string private _baseTokenURI;
  bool pubSaleStart;
  uint256 maxSupply = 120;
  uint256 pubPrice = 0.02 ether;
  uint256 mintLimit = 1;

  mapping(address => uint256) public claimed;

  constructor() ERC721Psi('MONONOKE CHIMERA', 'CHIMERA') {
    _setDefaultRoyalty(
      address(0xd2Cf1aa09dC1494E43a74cDa7Dc75c8d54E3099B),
      1000
    );
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function tokenURI(
    uint256 _tokenId
  ) public view virtual override(ERC721Psi) returns (string memory) {
    return string(abi.encodePacked(ERC721Psi.tokenURI(_tokenId), '.json'));
  }

  function pubMint() public payable nonReentrant {
    uint256 supply = totalSupply();
    require(pubSaleStart, 'Before sale begin.');
    _mintCheck(1, supply, pubPrice);

    claimed[msg.sender] += 1;
    _safeMint(msg.sender, 1);
  }

  function _mintCheck(
    uint256 _quantity,
    uint256 _supply,
    uint256 _cost
  ) private view {
    require(_supply + _quantity <= maxSupply, 'Max supply over');
    require(_quantity <= mintLimit, 'Mint quantity over');
    require(msg.value >= _cost, 'Not enough funds');
    require(
      claimed[msg.sender] + _quantity <= mintLimit,
      'Already claimed max'
    );
  }

  function ownerMint(address _address, uint256 _quantity) public onlyOwner {
    uint256 supply = totalSupply();
    require(supply + _quantity <= maxSupply, 'Max supply over');
    _safeMint(_address, _quantity);
  }

  // only owner
  function setBaseURI(string calldata _uri) external onlyOwner {
    _baseTokenURI = _uri;
  }

  function setPubsale(bool _state) public onlyOwner {
    pubSaleStart = _state;
  }

  function setMintLimit(uint256 _quantity) public onlyOwner {
    mintLimit = _quantity;
  }

  function setMaxSupply(uint256 _quantity) public onlyOwner {
    maxSupply = _quantity;
  }

  struct ProjectMember {
    address founder;
    address dev;
  }
  ProjectMember private _member;

  function setMemberAddress(address _founder, address _dev) public onlyOwner {
    _member.founder = _founder;
    _member.dev = _dev;
  }

  function withdraw() external onlyOwner {
    require(
      _member.founder != address(0) && _member.dev != address(0),
      'Please set member address'
    );

    uint256 balance = address(this).balance;
    Address.sendValue(payable(_member.founder), ((balance * 6000) / 10000));
    Address.sendValue(payable(_member.dev), ((balance * 4000) / 10000));
  }

  // OperatorFilterer
  function setApprovalForAll(
    address operator,
    bool approved
  ) public override onlyAllowedOperatorApproval(operator) {
    super.setApprovalForAll(operator, approved);
  }

  function approve(
    address operator,
    uint256 tokenId
  ) public override onlyAllowedOperatorApproval(operator) {
    super.approve(operator, tokenId);
  }

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public override onlyAllowedOperator(from) {
    super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public override onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  ) public override onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId, data);
  }

  // Royality
  function setRoyalty(
    address _royaltyAddress,
    uint96 _feeNumerator
  ) external onlyOwner {
    _setDefaultRoyalty(_royaltyAddress, _feeNumerator);
  }

  function supportsInterface(
    bytes4 _interfaceId
  ) public view virtual override(ERC721Psi, ERC2981) returns (bool) {
    return
      ERC721Psi.supportsInterface(_interfaceId) ||
      ERC2981.supportsInterface(_interfaceId);
  }
}