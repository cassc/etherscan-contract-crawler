// SPDX-License-Identifier: MIT

/**
         @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                        
        @@                                                                            @@@@                                    
       @@@                                                                                @@@                                  
       @@@                                                                                   @@                                 
       @@@      @@@@@@@@@@@@@@@@         @@@@@@@@@@@@@@@@        @@@@@@@@         @@@@@@       @@                                
       @@@      @@@@@@@@@@@@@@@@@@@      @@@@@@@@@@@@@@@@@@        @@@@@@@       @@@@@         @@@                               
       @@@      @@@@            @@@@     @@@@           @@@@         @@@@@@    @@@@@           @@@                               
       @@@      @@@@             @@@     @@@@             @@@          @@@@@  @@@@             @@@                               
       @@@      @@@@            @@@      @@@@            @@@@           @@@@@@@@               @@@                               
       @@@      @@@@@@@@@@@@@@@@@        @@@@@@@@@@@@@@@@@@@             @@@@@@                @@@                               
       @@@      @@@@@@@@@@@@@@@@@@@@     @@@@@@@@@@@@@@@@                 @@@@@@               @@@                               
       @@@      @@@@             @@@@    @@@@@@@@@@@@@                   @@@@@@@@@             @@@                               
       @@@      @@@@              @@@@   @@@@    @@@@@@@               @@@@   @@@@@            @@@                               
       @@@      @@@@            @@@@@@   @@@@      @@@@@@            @@@@@     @@@@@           @@@                               
       @@@      @@@@@@@@@@@@@@@@@@@@@    @@@@        @@@@@         @@@@@        @@@@@@         @@@                               
        @@       @@@@@@@@@@@@@@@@@@      @@@@         @@@@@@     @@@@@@          @@@@@@        @@@                               
        @@@          @@@@@@@@            @@@@          @@@@@@   @@@@@             @@@@@@@      @@@                               
          @@@                                                                                  @@@                               
            @@@@@                                                                             @@@                                
                @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                 
*/

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract BinaryDex is DefaultOperatorFilterer, ERC721A, ERC2981, Ownable {

  address private adminSigner;

  uint256 public MAX_SUPPLY = 7070;
  uint256 public constant MINT_PRICE = 0.079 ether;

  string private baseTokenUri;

  address public reserveAddress = 0xA04be43B1f1b0fCA3895E140Ddb1D545F99061D1;
  address public withdrawalAddress = 0xe1Ab071F2D67521E7d059B27329950d2E2dc9309;
  struct Coupon {
      bytes32 r;
      bytes32 s;
      uint8 v;
  }

  /**
    * The sale phase
    */
  enum SalePhase {
      Locked,
      Main,
      Waitlist,
      Public,
      Claim
  }

  bool public canWaitlistClaimSpot = false;
  mapping(address => uint256) public waitlistReservationList;
  address[] public waitlistReservedAddresses;
  uint256 public reserveAmount;

  SalePhase public phase = SalePhase.Locked;

  bool public isAlreadyReserved = false;
  bool public isMaxSupplySet = false;

  mapping(address => bool) private hasMintedBefore;
  mapping(address => uint256) public tokenToOwnerAtMint;

  address[] public minted;



  modifier callerIsUser() {
      require(tx.origin == msg.sender, "The caller is another contract");
      _;
  }

  constructor(string memory _baseUri, address _signer) ERC721A("Binary", "DEX") {
      baseTokenUri = _baseUri;
      adminSigner = _signer;
  }

  function tenTenMint(Coupon calldata coupon) external payable callerIsUser {
      require(phase == SalePhase.Main, "1010 mint not open for sale");
      require(!hasMintedBefore[msg.sender], "You have previously minted");
      require(_nextTokenId() - 1 < MAX_SUPPLY, "All tokens have been allocated.");
      require(msg.value >= MINT_PRICE, "Less than required amount");
      bytes32 digest = keccak256(abi.encode(msg.sender, true, true, true));
      require(_isVerifiedCoupon(digest, coupon), "Not authorised 1010");
      minted.push(msg.sender);
      tokenToOwnerAtMint[msg.sender] = _nextTokenId();
      hasMintedBefore[msg.sender] = true;
      _mint(msg.sender, 1);
  }

  function sixtySixtyMint(Coupon calldata coupon) external payable callerIsUser {
      require(phase == SalePhase.Main, "6060 mint not open for sale");
      require(!hasMintedBefore[msg.sender], "You have previously minted");
      require(_nextTokenId() - 1 < MAX_SUPPLY, "All tokens have been allocated.");
      require(msg.value >= MINT_PRICE, "Less than required amount");
      bytes32 digest = keccak256(abi.encode(msg.sender, false, true, true));
      require(_isVerifiedCoupon(digest, coupon), "Not authorised 6060");
      minted.push(msg.sender);
      tokenToOwnerAtMint[msg.sender] = _nextTokenId();
      hasMintedBefore[msg.sender] = true;
      _mint(msg.sender, 1);
  }

  function waitListMint(Coupon calldata coupon) external payable callerIsUser {
      require(phase == SalePhase.Waitlist, "Waitlist mint not open for sale");
      require(!hasMintedBefore[msg.sender], "You have previously minted");
      require(waitlistReservationList[msg.sender] == 0, "Already reserved");
      require((_nextTokenId() - 1) + waitlistReservedAddresses.length < MAX_SUPPLY, "All tokens have been allocated.");
      require(msg.value >= MINT_PRICE, "Less than required amount");
      bytes32 digest = keccak256(abi.encode(msg.sender, false, false, true));
      require(_isVerifiedCoupon(digest, coupon), "Not authorised waitlist");
      hasMintedBefore[msg.sender] = true;
      _mint(msg.sender, 1);
  }

  function publicMint(uint256 quantity) external payable callerIsUser {
      require(phase == SalePhase.Public, "Public mint not open for sale");
      require(quantity <= 100, "Max quantity reached");
      require((_nextTokenId() - 1) + waitlistReservedAddresses.length < MAX_SUPPLY, "All tokens have been allocated.");
      require(msg.value >= MINT_PRICE * quantity, "Less than required amount");
      _mint(msg.sender, quantity);
  }

  function waitlistReserve(Coupon calldata coupon) external payable callerIsUser {
    require(canWaitlistClaimSpot, "Waitlist claim spot not started");
    require(waitlistReservedAddresses.length < 6060, "Reservation full");
    require(msg.value >= MINT_PRICE, "Less than required amount");
    require(waitlistReservationList[msg.sender] == 0, "You have already reserved");
    bytes32 digest = keccak256(abi.encode(msg.sender, false, false, true));
    require(_isVerifiedCoupon(digest, coupon), "Not authorised waitlist");
    waitlistReservedAddresses.push(msg.sender);
    waitlistReservationList[msg.sender] = msg.value;
    reserveAmount += msg.value;
  }

  function claimWaitlistReserveFunds() external callerIsUser {
    require(phase == SalePhase.Claim, "Claim phase not started");
    require(waitlistReservationList[msg.sender] >= MINT_PRICE, "Not reserved or already airdropped");
    reserveAmount -= waitlistReservationList[msg.sender];
    uint256 amount = waitlistReservationList[msg.sender];
    waitlistReservationList[msg.sender] = 0;
    (bool success, ) = payable(msg.sender).call{value: amount}(new bytes(0)); 
    require(success, "Failed to send Ether");
  }

  function setPhase(SalePhase _salePhase) external onlyOwner {
      if (_salePhase == SalePhase.Main) {
        canWaitlistClaimSpot = true;
      } else {
        canWaitlistClaimSpot = false;
      }
      phase = _salePhase;
  }

  //URI to metadata
  function _baseURI() internal view virtual override returns (string memory) {
      return baseTokenUri;
  }

  function setBaseUri(string calldata _newTokenURI) external onlyOwner {
      baseTokenUri = _newTokenURI;
  }

  function withdraw() external onlyOwner {
      require(phase == SalePhase.Locked, "Not in locked phase");
      uint256 withdrawalAmount = address(this).balance - reserveAmount;
      (bool success, ) = payable(withdrawalAddress).call{value: withdrawalAmount}(new bytes(0)); 
      require(success, "Failed to send Ether");
  }

  function _startTokenId() internal view virtual override returns (uint256) {
      return 1;
  }

  function internalReserve() external onlyOwner {
      require(!isAlreadyReserved, "Already reserved 200");
      isAlreadyReserved = true;
      _mint(reserveAddress, 200);
  }

  function airdrop(address[] calldata _receivers) external onlyOwner {
    for (uint256 i = 0; i < _receivers.length; i++) {
      if (waitlistReservationList[_receivers[i]] < MINT_PRICE) {
        continue;
      }
      reserveAmount -= waitlistReservationList[_receivers[i]];
      waitlistReservationList[_receivers[i]] = 0;
      _mint(_receivers[i], 1);
    }
  }

  function claimAllUnminted() external onlyOwner {
      require(phase == SalePhase.Locked, "Not in locked phase");
      uint256 quantity = (MAX_SUPPLY - _nextTokenId()) + 1;
      require(quantity >= 1, "All minted out");
      _mint(reserveAddress, quantity);
  }

  function setMaxSupply(uint256 quantity) external onlyOwner {
      require(!isMaxSupplySet, "Max supply has already been set once");
      isMaxSupplySet = true;
      MAX_SUPPLY = quantity;
  }

  function getMintedLength() external view returns (uint256) {
      return minted.length;
  }

  function getWaitlistReserveLength() external view returns (uint256) {
    return waitlistReservedAddresses.length;
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
  ) public payable override onlyAllowedOperator(operator) {
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

  function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyOwner {
      _setDefaultRoyalty(receiver, feeNumerator);
  }

  function deleteDefaultRoyalty() external onlyOwner {
      _deleteDefaultRoyalty();
  }

  function setAdminSigner(address _signer) external onlyOwner {
      adminSigner = _signer;
  }

  function setWithdrawalAddress(address _withdrawalAddress) external onlyOwner {
      withdrawalAddress = _withdrawalAddress;
  }

  function _isVerifiedCoupon(
      bytes32 _digest,
      Coupon calldata _coupon
  ) internal view returns (bool) {
      address signer = ecrecover(_digest, _coupon.v, _coupon.r, _coupon.s);
      require(signer != address(0), "ECDSA: invalid signature");
      return signer == adminSigner;
  }

  function supportsInterface(
      bytes4 interfaceId
  ) public view virtual override(ERC721A, ERC2981) returns (bool) {
      return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
  }
}