// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "@openzeppelin/contracts/access/Ownable.sol";
import './ERC721A.sol';
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract ERC721Custom is ERC721A, Ownable, ReentrancyGuard, DefaultOperatorFilterer {
  using Strings for uint256;

  uint256 public maxSupply;
  uint256 public mintPrice;
  uint256 public wlMintPrice;
  uint256 public maxBatchMint = 5;
  uint256 public splitPercent = 10;
  string public baseURI;
  bytes32 public merkleRoot;
  bool public airdropDone = false;
  bool public whitelistDone = false;
  bool public revealed = false;

  address public devAddress = 0xEfF5ffD4659b9FaB41c2371B775d37F00b287CCf;
  mapping(address => bool) public airdroped;
  mapping(address => bool) public whitelistClaimed;

  constructor(
    address _admin,
    string memory _baseURI,
    string memory _tokenName,
    string memory _tokenSymbol,
    bytes32 _merkleRoot,
    uint256 _mintPrice,
    uint256 _wlMintPrice,
    uint256 _maxSupply
  ) ERC721A(_tokenName, _tokenSymbol) {
    transferOwnership(_admin);
    baseURI = _baseURI;
    merkleRoot = _merkleRoot;
    mintPrice = _mintPrice;
    wlMintPrice = _wlMintPrice;
    maxSupply = _maxSupply;
  }

  modifier whitelistMintCompliance(address to, bytes32[] calldata _merkleProof) {
    require(airdropDone, "Can't mint before the end of airdrop");
    require(totalSupply() + 1 <= maxSupply, "There is no more token :(");
    require(checkMerkleProof(to, _merkleProof), "You are not whitelisted maybe another time in another world");
    require(!whitelistClaimed[to], "You already claim a free mint with this wallet, create a new one, fucking botters");
    require(msg.value >= wlMintPrice, "Huhu bad amount bro, maybe send more ?!");
    _;
  }

  modifier publicMintCompliance(uint256 _amount) {
    require(airdropDone, "Can't mint before the end of airdrop");
    require(whitelistDone, "Can't mint before whitelisted guys sry not sry !");
    require(_amount > 0 && _amount <= maxBatchMint, "You can mint from 1 to 5 token not less, not more, less is more");
    require(totalSupply() + _amount <= maxSupply, "Sorry bro no more token you miss your luck");
    require(msg.value >= mintPrice * _amount, "Huhu bad amount bro, maybe send more ?!");
    _;
  }

  modifier airdropMintCompliance(uint256 _amount, address to) {
    require(!airdropDone, "Can't airdrop if airdrop is done");
    require(!airdroped[to], "You already airdroped token to this address");
    require(totalSupply() + _amount <= maxSupply, "There is no more token :(");
    _;
  }

  function checkMerkleProof(address to, bytes32[] calldata _merkleProof) public view returns(bool) {
    bytes32 leaf = keccak256(abi.encodePacked(to));
    if (MerkleProof.verify(_merkleProof, merkleRoot, leaf)) {
      return true;
    }
    if (whitelistClaimed[to]) {
      return false;
    }
    return false;
  }

  function airdropMint(uint256 amount, address to) public onlyOwner airdropMintCompliance(amount, to) {
    airdroped[to] = true;
    _mint(to, amount);
  }

  function whitelistMint(bytes32[] calldata _merkleProof) public payable whitelistMintCompliance(_msgSender(),_merkleProof) {
    whitelistClaimed[_msgSender()] = true;
    _mint(_msgSender(), 1);
  }

  function mint(uint256 amount) public payable publicMintCompliance(amount) {
    _mint(_msgSender(), amount);
  }

  function withdrawFund(address to) public onlyOwner nonReentrant {
    require(address(this).balance > 0, "Shit nothing to take here, bad marketing mb !");
    (bool hs, ) = payable(devAddress).call{value: address(this).balance * splitPercent / 100}('');
    require(hs);
    (bool os, ) = payable(to).call{value: address(this).balance}('');
    require(os);
  }

  function setAirdropDone() public onlyOwner {
    airdropDone = true;
  }

  function setWhitelistDone() public onlyOwner {
    whitelistDone = true;
  }

  function reveal(string memory newUri) public onlyOwner {
    require(!revealed, "Already revealed you can't rekt your customers bro comon, if you failed AHHAHAHA cheh");
    baseURI = newUri;
    revealed = true;
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC721A)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }

  function tokenURI(uint256 _tokenId)
    public
    view
    virtual
    override(ERC721A)
    returns (string memory)
  {
    if (!revealed) {
      return string(abi.encodePacked(baseTokenURI() ,'.json'));
    }
    return string(abi.encodePacked(baseTokenURI(), _tokenId.toString(), '.json'));
  }

  function baseTokenURI() public view returns (string memory) {
    return baseURI;
  }

  function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
    super.setApprovalForAll(operator, approved);
  }

  function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
    super.approve(operator, tokenId);
  }

  function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
    super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
    public
    override
    onlyAllowedOperator(from)
  {
    super.safeTransferFrom(from, to, tokenId, data);
  }
}