//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "erc721a/contracts/ERC721A.sol";

contract Outlaws is
  DefaultOperatorFilterer,
  ERC721A,
  Ownable,
  PaymentSplitter,
  AccessControl
{
  using SafeMath for uint256;

  uint256 private _tokenCount;

  enum SaleState {
    INACTIVE,
    PRESALE,
    SALE
  }
  SaleState public saleState = SaleState.INACTIVE;
  uint256 public _discountedPrice = 0.04 ether;
  uint256 public _price = 0.05 ether;

  uint public constant MAX_SUPPLY = 10000;
  uint public constant MAX_PER_MINT = 10;

  string public baseTokenURI;

  bytes32 private freeMerkleRoot =
    0xdaa4a4907a9dec10941cca1a666dbe387a9c9105188dafc74586f7682deb527a;
  bytes32 private discountedMerkleRoot =
    0xc735ca66e01325f5ccbb3b61d635426fac1068ca88c3864eaccfe18f2f9cbbc9;

  mapping(address => bool) public usedDiscount;
  mapping(address => uint) public presaleMintsUsed;

  bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

  event Mint(address _to, uint _count);

  constructor(
    string memory baseURI,
    string memory name,
    string memory symbol,
    address[] memory payees,
    uint256[] memory shares
  ) ERC721A(name, symbol) PaymentSplitter(payees, shares) {
    setBaseURI(baseURI);
    _setupRole(ADMIN_ROLE, msg.sender);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseTokenURI;
  }

  function setBaseURI(string memory _baseTokenURI) public onlyOwner {
    baseTokenURI = _baseTokenURI;
  }

  function supportsInterface(
    bytes4 interfaceId
  ) public view virtual override(ERC721A, AccessControl) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  function getCost(
    uint _count,
    address _caller,
    bytes32[] calldata _merkleProof
  ) public view returns (uint256) {
    require(
      _count > 0 && _count <= MAX_PER_MINT,
      "Outlaws: Must mint between 1 and 10 inclusive"
    );

    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    if (usedDiscount[_caller]) {
      return _price.mul(_count);
    } else if (MerkleProof.verify(_merkleProof, freeMerkleRoot, leaf)) {
      return _price.mul(_count - 1);
    } else if (MerkleProof.verify(_merkleProof, discountedMerkleRoot, leaf)) {
      return _discountedPrice + _price.mul(_count - 1);
    } else {
      return _price.mul(_count);
    }
  }

  function presaleMint(
    uint _count,
    bytes32[] calldata _merkleProof
  ) public payable {
    require(saleState == SaleState.PRESALE, "Outlaws: Not currently presale");
    require(
      presaleMintsUsed[msg.sender] + _count <= 5,
      "Outlaws: Not enough presale mints remaining"
    );

    require(
      _tokenCount.add(_count) <= MAX_SUPPLY,
      "Outlaws: You are minting too many"
    );

    require(_count > 0, "Outlaws: Must mint more than 0");

    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    require(
      MerkleProof.verify(_merkleProof, freeMerkleRoot, leaf) ||
        MerkleProof.verify(_merkleProof, discountedMerkleRoot, leaf),
      "Outlaws: Invalid proof"
    );

    require(
      msg.value == getCost(_count, msg.sender, _merkleProof),
      "Outlaws: Not enough ether to purchase NFTs"
    );

    _tokenCount += _count;
    _mint(msg.sender, _count);

    usedDiscount[msg.sender] = true;
    presaleMintsUsed[msg.sender] = presaleMintsUsed[msg.sender] + _count;

    emit Mint(msg.sender, _count);
  }

  function mint(uint _count, bytes32[] calldata _merkleProof) public payable {
    require(
      saleState == SaleState.SALE,
      "Outlaws: You are not able to mint right now"
    );
    require(
      _tokenCount.add(_count) <= MAX_SUPPLY,
      "Outlaws: You are minting too many"
    );
    require(
      _count > 0 && _count <= MAX_PER_MINT,
      "Outlaws: You are minting too many"
    );
    require(
      msg.value == getCost(_count, msg.sender, _merkleProof),
      "Outlaws: Not enough ether to purchase NFTs"
    );

    _tokenCount += _count;
    _mint(msg.sender, _count);

    if (!usedDiscount[msg.sender]) {
      usedDiscount[msg.sender] = true;
    }

    emit Mint(msg.sender, _count);
  }

  function reserveNFTs(uint _count, address _to) public onlyOwner {
    require(_count > 0, "Outlaws: Must mint more than 0");
    require(
      _tokenCount.add(_count) <= MAX_SUPPLY,
      "Outlaws: Not enough NFTs left to reserve"
    );

    _mint(_to, _count);
    emit Mint(_to, _count);
  }

  function addAdmin(address account) public onlyOwner {
    _grantRole(ADMIN_ROLE, account);
  }

  function setSaleState(SaleState _newState) public onlyRole(ADMIN_ROLE) {
    saleState = _newState;
  }

  function setPrice(uint256 _newPrice) public onlyRole(ADMIN_ROLE) {
    _price = _newPrice;
  }

  function setDiscountedPrice(uint256 _newPrice) public onlyRole(ADMIN_ROLE) {
    _discountedPrice = _newPrice;
  }

  function setFreeMerkleRoot(
    bytes32 _newMerkleRoot
  ) public onlyRole(ADMIN_ROLE) {
    freeMerkleRoot = _newMerkleRoot;
  }

  function setDiscountedMerkleRoot(
    bytes32 _newMerkleRoot
  ) public onlyRole(ADMIN_ROLE) {
    discountedMerkleRoot = _newMerkleRoot;
  }

  // Withdraw all eth. Should only be used if PaymentSplitter isn't working properly
  function withdraw() public payable onlyOwner {
    uint balance = address(this).balance;
    require(balance > 0, "No ether left to withdraw");

    (bool success, ) = (msg.sender).call{ value: balance }("");
    require(success, "Transfer failed.");
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