// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract VendyNft is ERC721A, ERC2981, Ownable {

    address private adminSigner;

    uint256 public constant MAX_SUPPLY = 100;
    string private baseTokenURI;

    struct Coupon {
        bytes32 r;
        bytes32 s;
        uint8 v;
    }

    mapping(address => uint256) public tokenIdByAddress;

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    /**
    * The sale phase
    */
    enum SalePhase {
        Locked,
        Started
    }

    SalePhase public phase = SalePhase.Locked;

    constructor(string memory baseUri, address _signer) ERC721A("Atomic Slime Soda", "ASS") {
      adminSigner = _signer;
      _setDefaultRoyalty(msg.sender, 500);
      baseTokenURI = baseUri;
      _mint(msg.sender, 8);
    }

    function mint(Coupon memory coupon) external callerIsUser {
      require(tokenIdByAddress[msg.sender] == 0, "You cannot mint again");
      require(phase == SalePhase.Started, "Mint has not started yet");
      require(_nextTokenId() != MAX_SUPPLY + 1, "All tokens have been distributed.");
      
      bytes32 digest = keccak256(
          abi.encode(msg.sender, false)
      );

      require(
        _isVerifiedCoupon(digest, coupon), 
        "Invalid coupon"
      );

      tokenIdByAddress[msg.sender] = _nextTokenId();

      _mint(msg.sender, 1);
    }

    //URI to metadata
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory _newTokenURI) external onlyOwner {
        baseTokenURI = _newTokenURI;
    }

    function setRoyaltyFee(address receiver, uint96 feeInBps) external onlyOwner {
      _setDefaultRoyalty(receiver, feeInBps);
    }

    function setAdminSigner(address _signer) external onlyOwner {
      adminSigner = _signer;
    }
    
    // Based on phase we need to change the mint price
    function setPhase(SalePhase salePhase) external onlyOwner {
      phase = salePhase;
    }

    function claimAllUnminted() external onlyOwner {
      require(phase == SalePhase.Locked, "The contract must be locked before you can claim all unminted to the treasury");

      uint256 quantity = (MAX_SUPPLY - _nextTokenId()) + 1;
      _mint(msg.sender, quantity);
    }

    /// @dev check that the coupon sent was signed by the admin signer
    function _isVerifiedCoupon(bytes32 digest, Coupon memory coupon) internal view returns (bool) {
      address signer = ecrecover(digest, coupon.v, coupon.r, coupon.s);
      require(signer != address(0), 'ECDSA: invalid signature');
      return signer == adminSigner;
    }

    function _startTokenId() internal view virtual override returns(uint256) {
      return 1;
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721A, ERC2981) returns (bool) {
      return 
          ERC721A.supportsInterface(interfaceId) || 
          ERC2981.supportsInterface(interfaceId);
    }
}