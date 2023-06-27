//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "erc721a/contracts/ERC721A.sol";

contract OrangApes is
  ERC721A,
  Ownable,
  PaymentSplitter,
  AccessControl,
  DefaultOperatorFilterer
{
  using SafeMath for uint256;

  enum Token {
    ETH,
    PSYOP
  }
  bool public isMintingActive = false;

  address _tokenAddress;
  uint256 private _currentTokenCount;

  uint256 public _price = 0.0069 ether;
  uint256 public _pysopPrice = 17500 ether; // ether keyword is just *10^18

  uint public constant MAX_SUPPLY = 10000;
  uint public constant MAX_PER_MINT = 10;

  string public baseTokenURI;

  bytes32 private _merkleRoot =
    0x5488f5943029b733f146c0fc7600b47ec8d0fdf0b24bb40d450f5acbe9cd109d;
  mapping(address => bool) public usedWhitelist;

  bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

  event Mint(address _to, uint _count);

  constructor(
    string memory baseURI,
    string memory name,
    string memory symbol,
    address[] memory payees,
    uint256[] memory shares
  ) ERC721A(name, symbol) PaymentSplitter(payees, shares) {
    _setupRole(ADMIN_ROLE, msg.sender);
    setBaseURI(baseURI);
  }

  function getCost(
    uint _count,
    Token token,
    bytes32[] calldata _merkleProof
  ) public view returns (uint256) {
    require(
      _count > 0 && _count <= MAX_PER_MINT,
      "OrangApes: Must mint between 1 and 10"
    );

    uint256 priceToUse;
    if (token == Token.ETH) {
      priceToUse = _price;
    } else {
      priceToUse = _pysopPrice;
    }

    if (usedWhitelist[msg.sender]) {
      return priceToUse.mul(_count);
    }

    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    if (MerkleProof.verify(_merkleProof, _merkleRoot, leaf)) {
      return priceToUse.mul(_count - 1);
    }

    return priceToUse.mul(_count);
  }

  function mintWithEth(
    uint _count,
    bytes32[] calldata _merkleProof
  ) public payable {
    require(
      isMintingActive || hasRole(ADMIN_ROLE, msg.sender),
      "OrangApes: Minting not active"
    );
    require(
      _currentTokenCount.add(_count) < MAX_SUPPLY,
      "OrangApes: Minting too many"
    );
    require(
      _count > 0 && _count <= MAX_PER_MINT,
      "OrangApes: Minting too many"
    );
    require(
      msg.value == getCost(_count, Token.ETH, _merkleProof),
      "OrangApes: Not enough ETH provided"
    );

    _currentTokenCount += _count;

    _mint(msg.sender, _count);

    if (
      !usedWhitelist[msg.sender] &&
      _price.mul(_count) != getCost(_count, Token.ETH, _merkleProof)
    ) {
      usedWhitelist[msg.sender] = true;
    }

    emit Mint(msg.sender, _count);
  }

  function mintWithPsyop(uint _count, bytes32[] calldata _merkleProof) public {
    require(
      isMintingActive || hasRole(ADMIN_ROLE, msg.sender),
      "OrangApes: Minting not active"
    );
    require(
      _currentTokenCount.add(_count) < MAX_SUPPLY,
      "OrangApes: Minting too many"
    );
    require(
      _count > 0 && _count <= MAX_PER_MINT,
      "OrangApes: Minting too many"
    );

    ERC20(_tokenAddress).transferFrom(
      msg.sender,
      address(this),
      getCost(_count, Token.PSYOP, _merkleProof)
    );

    _currentTokenCount += _count;

    _mint(msg.sender, _count);

    if (
      !usedWhitelist[msg.sender] &&
      _price.mul(_count) != getCost(_count, Token.PSYOP, _merkleProof)
    ) {
      usedWhitelist[msg.sender] = true;
    }

    emit Mint(msg.sender, _count);
  }

  function reserveNFTs(uint _count, address _to) public onlyRole(ADMIN_ROLE) {
    require(_count > 0, "OrangApes: Must mint more than 0");
    require(
      _currentTokenCount.add(_count) < MAX_SUPPLY,
      "OrangApes: Minting too many"
    );

    _currentTokenCount += _count;

    _mint(_to, _count);

    emit Mint(_to, _count);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseTokenURI;
  }

  function addAdmin(address account) public onlyOwner {
    _grantRole(ADMIN_ROLE, account);
  }

  function setPrice(uint256 _newPrice) public onlyRole(ADMIN_ROLE) {
    _price = _newPrice;
  }

  function setPsyopPrice(uint256 _newPrice) public onlyRole(ADMIN_ROLE) {
    _pysopPrice = _newPrice;
  }

  function setMerkleRoot(bytes32 _newMerkleRoot) public onlyRole(ADMIN_ROLE) {
    _merkleRoot = _newMerkleRoot;
  }

  function setBaseURI(string memory _baseTokenURI) public onlyRole(ADMIN_ROLE) {
    baseTokenURI = _baseTokenURI;
  }

  function setPsyopAddress(address tokenAddress) public onlyRole(ADMIN_ROLE) {
    _tokenAddress = tokenAddress;
  }

  function toggleMinting() public onlyRole(ADMIN_ROLE) {
    isMintingActive = !isMintingActive;
  }

  function withdrawPsyop(
    address _to,
    uint256 _amount
  ) public onlyRole(ADMIN_ROLE) {
    ERC20(_tokenAddress).transfer(_to, _amount);
  }

  function supportsInterface(
    bytes4 interfaceId
  ) public view virtual override(ERC721A, AccessControl) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  function setApprovalForAll(
    address operator,
    bool approved
  ) public override onlyAllowedOperatorApproval(operator) {
    super.setApprovalForAll(operator, approved);
  }

  function approve(
    address operator,
    uint256 tokenId
  ) public payable override onlyAllowedOperatorApproval(operator) {
    super.approve(operator, tokenId);
  }

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public payable override onlyAllowedOperator(from) {
    super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public payable override onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  ) public payable override onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId, data);
  }
}