// SPDX-License-Identifier: MIT

//Author: Mors (https://twitter.com/MorsNFT)
pragma solidity >=0.7.0 <0.9.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";

contract NFTContract is ERC721A, Ownable, DefaultOperatorFilterer, PaymentSplitter {

  enum SalePhase {
        Locked,
        Whitelist,
        Public
    }
  
  SalePhase public phase = SalePhase.Locked;
  
  uint256 public cost = 0.0125 ether;
  uint256 public maxSupply = 4444;
  uint256 public mintMax = 2;
  string public baseURI;
  address public couponSigner;

  struct Coupon {
		bytes32 r;
		bytes32 s;
		uint8 v;
	}

    enum CouponType {
    Whitelist
	}

  constructor(
    address[] memory _payees, 
    uint256[] memory _shares,
    string memory _name,
    string memory _symbol
  ) ERC721A(_name, _symbol) PaymentSplitter(_payees, _shares) payable {
  }

  modifier callerIsUser() {
    
    require(tx.origin == msg.sender, "The caller is another contract");
    _;
  }

  /**
     * * Set Coupon Signer
     * @dev Set the coupon signing wallet
     * @param couponSigner_ The new coupon signing wallet address
     */
    function setCouponSigner(address couponSigner_) external onlyOwner {
        couponSigner = couponSigner_;
    }

    // !====== Helper Functions ====== //
    /**
     * * Verify Coupon
     * @dev Verify that the coupon sent was signed by the coupon signer and is a valid coupon
     * @notice Valid coupons will include coupon signer, type [Reserve, AllowlistPrime, Allowlist], address, and allotted mints
     * @notice Returns a boolean value
     * @param digest_ The digest
     * @param coupon_ The coupon
     */
	function _isVerifiedCoupon(bytes32 digest_, Coupon memory coupon_) internal view returns (bool) {
		address signer = ecrecover(digest_, coupon_.v, coupon_.r, coupon_.s);
    require(signer != address(0), 'Zero Address');
		return signer == couponSigner;
	}


  //MINT
  function whitelistMint(uint256 _amount, Coupon memory _coupon) external payable callerIsUser {
    require(phase == SalePhase.Whitelist, "SALE NOT OPEN");
    require(_totalMinted() + _amount < maxSupply + 1, "Max Supply");
    require(numberMinted(msg.sender) + _amount < mintMax + 1, "Out of mints");
    bytes32 digest = keccak256(
			abi.encode(CouponType.Whitelist, msg.sender)
		);
    require(_isVerifiedCoupon(digest, _coupon), "Invalid Coupon");
    require(msg.value == cost * _amount, "NOT ENOUGH ETHER");
    _mint(msg.sender, _amount);
  }

  function publicMint(uint256 _amount) external payable callerIsUser {
    require(phase == SalePhase.Public, "SALE NOT OPEN");
    require(_totalMinted() + _amount < maxSupply + 1, "Max Supply");
    require(numberMinted(msg.sender) + _amount < mintMax + 1, "Out of mints");
    require(msg.value == cost * _amount, "NOT ENOUGH ETHER");
    _mint(msg.sender, _amount);
  }

  function ownerMint(uint256 _amount) external onlyOwner {
    require(_totalMinted() + _amount < maxSupply + 1, "Max Supply");
    _mint(msg.sender, _amount);
  }


  function setCost(uint256 _cost) external onlyOwner {
    cost = _cost;
  }

  function setMaxMint(uint256 _max) external onlyOwner {
    mintMax = _max;
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

  //WITHDRAW
  function withdraw() external onlyOwner {
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
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