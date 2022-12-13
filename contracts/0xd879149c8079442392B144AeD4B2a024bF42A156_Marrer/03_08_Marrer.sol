// SPDX-License-Identifier: MIT

//Author: Mors (https://twitter.com/MorsNFT)
pragma solidity >=0.7.0 <0.9.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract Marrer is ERC721A, Ownable, DefaultOperatorFilterer {
  enum SalePhase {
        Locked,
        Whitelist,
        Allowlist,
        Public
    }
  
  SalePhase public phase = SalePhase.Locked;
  
  uint256 public whitelistCost = 0.03 ether;
  uint256 public publicCost = 0.04 ether;
  uint256 public maxSupply = 3333;
  uint256 public preSaleMaxMint = 1;
  uint256 public publicMaxMint = 3;
  address public couponSigner = 0x80f33b75f5b9edE51FdeA3104FA0df7B469B962a;
  string public baseURI;

  struct Coupon {
		bytes32 r;
		bytes32 s;
		uint8 v;
	}

    enum CouponType {
    Whitelist,
    Allowlist
	}

  constructor(
    string memory _name,
    string memory _symbol
  ) ERC721A(_name, _symbol) {
  }


  modifier mintConfigs(uint256 _amount) {
    require(_totalMinted() + _amount < maxSupply + 1, "Max Supply");
    require(tx.origin == msg.sender, "The caller is another contract");
    _;
  }

  function setCouponSigner(address couponSigner_) external onlyOwner {
      couponSigner = couponSigner_;
  }

	function isVerifiedCoupon(bytes32 digest_, Coupon memory coupon_) internal view returns (bool) {
		address signer = ecrecover(digest_, coupon_.v, coupon_.r, coupon_.s);
    require(signer != address(0), 'Zero Address');
		return signer == couponSigner;
	}

  //MINT
  function whitelistMint(uint256 _amount, Coupon memory _coupon) external payable mintConfigs(_amount) {
    require(phase == SalePhase.Whitelist, "SALE NOT OPEN");
    require(_numberMinted(msg.sender) + _amount < preSaleMaxMint + 1, "Out of mints");
    bytes32 digest = keccak256(
			abi.encode(CouponType.Whitelist, msg.sender)
		);
    require(isVerifiedCoupon(digest, _coupon), "Invalid Coupon");
    require(msg.value == whitelistCost, "NOT ENOUGH ETHER");
    _mint(msg.sender, _amount);
  }

  function allowlistMint(uint256 _amount, Coupon memory _coupon) external payable mintConfigs(_amount) {
    require(phase == SalePhase.Allowlist, "SALE NOT OPEN");
    require(_numberMinted(msg.sender) + _amount < preSaleMaxMint + 1, "Out of mints");
    bytes32 digest = keccak256(
			abi.encode(CouponType.Allowlist, msg.sender)
		);
    require(isVerifiedCoupon(digest, _coupon), "Invalid Coupon");
    require(msg.value == whitelistCost, "NOT ENOUGH ETHER");
    _mint(msg.sender, _amount);
  }

  function publicMint(uint256 _amount) external payable mintConfigs(_amount) {
    require(phase == SalePhase.Public, "SALE NOT OPEN");
    require(_numberMinted(msg.sender) + _amount < publicMaxMint + 1, "Out of mints");
    require(msg.value == publicCost, "NOT ENOUGH ETHER");
    _mint(msg.sender, _amount);
  }

  function ownerMint(address _to, uint256 _amount) external onlyOwner {
    require(_totalMinted() + _amount < maxSupply + 1, "Max Supply");
    _mint(_to, _amount);
  }

  //SETTERS
  function setPublicCost(uint256 _publicCost) external onlyOwner {
    publicCost = _publicCost;
  }

  function setWhitelistCost(uint256 _whitelistCost) external onlyOwner {
    whitelistCost = _whitelistCost;
  }

  function setPresaleMintMax(uint256 _max) external onlyOwner {
    preSaleMaxMint = _max;
  }
  function setPublicMintMax(uint256 _max) external onlyOwner {
    publicMaxMint = _max;
  }

  function setSalePhase(SalePhase _phase) external onlyOwner {
    phase = _phase;
  }

  function numberMinted(address owner) external view returns (uint256) {
    return _numberMinted(owner);
  }

  //METADATA
  function _startTokenId() internal pure override returns (uint256) {
    return 1;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  function setBaseURI(string calldata _newURI) external onlyOwner {
    baseURI = _newURI;
  }

  //Transfer
  function transfer(address payable _to, uint _amount) external onlyOwner {
        // Note that "to" is declared as payable
        (bool success, ) = _to.call{value: _amount}("");
        require(success, "Transfer failed.");  
  }

  //override
  function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
    super.setApprovalForAll(operator, approved);
  }

  function approve(address operator, uint256 tokenId) public payable override onlyAllowedOperatorApproval(operator) {
    super.approve(operator, tokenId);
  }

  function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
    super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
      super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
    public
    payable
    override
    onlyAllowedOperator(from)
  {
    super.safeTransferFrom(from, to, tokenId, data);
  }
}