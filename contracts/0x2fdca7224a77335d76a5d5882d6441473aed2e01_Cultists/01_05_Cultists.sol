// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Cultists is ERC721A, Ownable  {

  error PublicSaleNotActive();
  error WhitelistSaleNotActive();
  error MaxSupplyReached();
  error MaxPerWalletReached();
  error MaxPerTxReached();
  error NotEnoughETH();
  error NoContractMint();
  error InvalidCoupon();
  
  SalePhase public phase = SalePhase.Locked;
  
  uint256 public cost = 0.005 ether;
  uint256 public maxSupply = 4000;
  uint256 public wlMaxPerWallet = 2;
  uint256 public publicMaxPerWallet = 5;
  string public baseURI;
  address public couponSigner;

  struct Coupon {
		bytes32 r;
		bytes32 s;
		uint8 v;
   }

  enum SalePhase {
        Locked,
        Whitelist,
        Public
    }

  enum CouponType {
    Whitelist
	}

  constructor(
    string memory _name,
    string memory _symbol
  ) ERC721A(_name, _symbol) payable {
    couponSigner = 0x76EFeDd765A3519A032C7e682912038AeC9242f5;
    baseURI = "ipfs://bafybeifjr6jrjbdhvfv3zpyd7o7i7kg3umr6qcbmgk5c32g4pboln24bju/";
  }

  modifier mintCompliance(uint256 _amount) {
    if (_totalMinted() + _amount > maxSupply) revert MaxSupplyReached();
    if (tx.origin != msg.sender) revert NoContractMint();
    _;
  }

  function setCouponSigner(address couponSigner_) external onlyOwner {
    couponSigner = couponSigner_;
  }

	function _isVerifiedCoupon(bytes32 digest_, Coupon memory coupon_) internal view returns (bool) {
	address signer = ecrecover(digest_, coupon_.v, coupon_.r, coupon_.s);
    require(signer != address(0), 'Zero Address');
		return signer == couponSigner;
	}

  //MINT
  function whitelistMint(uint256 _amount, Coupon memory _coupon) external payable mintCompliance(_amount) {
    if (phase != SalePhase.Whitelist) revert WhitelistSaleNotActive();
    if (_numberMinted(msg.sender) + _amount > wlMaxPerWallet) revert MaxPerWalletReached();
    bytes32 digest = keccak256(
			abi.encode(CouponType.Whitelist, msg.sender)
		);
    if (!(_isVerifiedCoupon(digest, _coupon))) revert InvalidCoupon();
    if (msg.value < cost * _amount) revert NotEnoughETH();
    _mint(msg.sender, _amount);
  }

  function publicMint(uint256 _amount) external payable mintCompliance(_amount) {
    if (phase != SalePhase.Public) revert PublicSaleNotActive();
    if (_numberMinted(msg.sender) + _amount > publicMaxPerWallet) revert MaxPerWalletReached();
    if (_amount > 2) revert MaxPerTxReached();
    if (msg.value < cost * _amount) revert NotEnoughETH();
    _mint(msg.sender, _amount);
  }

  function ownerMint(uint256 _amount) external onlyOwner {
    if (_totalMinted() + _amount > maxSupply) revert MaxSupplyReached();
    _mint(msg.sender, _amount);
  }

  function setCost(uint256 _cost) external onlyOwner {
    cost = _cost;
  }

  function setWlMaxMint(uint256 _max) external onlyOwner {
    wlMaxPerWallet = _max;
  }

  function setPublicMaxMint(uint256 _max) external onlyOwner {
    publicMaxPerWallet = _max;
  }

  function setSalePhase(SalePhase _phase) external onlyOwner {
    phase = _phase;
  }

  function numberMinted(address owner) public view returns (uint256) {
    return _numberMinted(owner);
  }

  //METADATA
  function _startTokenId() internal pure override returns (uint256) {
    return 1;
  }

  function setBaseURI(string calldata _newURI) external onlyOwner {
    baseURI = _newURI;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  function setSupply(uint256 _newSupply) external onlyOwner {
    maxSupply = _newSupply;
  } 

  //WITHDRAW
  function withdraw() external onlyOwner {
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success, "Transfer failed.");
  }
}