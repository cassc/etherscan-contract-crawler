// SPDX-License-Identifier: MIT
pragma solidity ^ 0.8.14;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import  "@openzeppelin/contracts/utils/Strings.sol";
import "erc721a/contracts/ERC721A.sol";
import "../libraries/libraryfile.sol";
// import { ILandz } from "./ILandz.sol";

contract Landz is ERC721A, Pausable, Ownable {
  using Strings for uint256;

  uint16 public index = 1;
  uint16 public hqIndex;
  uint16 public museumIndex;
  uint16 public mansionIndex;
  /**
  * @notice counter for free Hq mint
  */
  uint8 public freeMintHqCounter = 15;
  /**
  * @notice counter for free Museum mint
  */
  uint8 public freeMintMuseumCounter = 45;
  /**
  * @notice counter for free Mansion mint
  */
  uint8 public freeMintMansionCounter = 150;
  bool private isGiveAway;
  /**
  * @notice define base Uri
  */
  string public baseURI = "https://nft-api.landz.io/metadata/";
  /**
  * @notice store mint count per wallet address
  */
  mapping(address => uint16) public mintsPerAddressCount;
  /**
  * @notice store if free minted has been used per wallet address
  */
  mapping(address => bool) public isFreeMinted;
  /**
  * @notice store Nft type per token identifier
  */
  mapping(uint256 => DataLibrary.NftType) public tokenIdNftTypes;

  event NewURI(string newURI);
  event WithdrawnPayment(uint256 landzBalance, uint256 advisorBalanceA, uint256 advisorBalanceB, uint256 advisorBalanceC, uint256 advisorBalanceD);
  event updatePhase(DataLibrary.SalePhase phase);

  /**
  * @notice indicates the current phase
  */
  DataLibrary.SalePhase public phase = DataLibrary.SalePhase.Phase01;

  constructor() ERC721A("Landz", "LDZ") {}

  /**
  * @notice check coupon by coupon type
  */
  modifier verifyCoupon(DataLibrary.Coupon memory coupon, DataLibrary.CouponType couponType) {
    bytes32 digest = keccak256(
        abi.encode(couponType, msg.sender)
    );
    require(Library.isVerifiedCoupon(digest, coupon), "001");
    _;
  }

  /**
  * @dev setPhase updates the phase
  *
  * Emits a {Unpaused} event.
  *
  * Requirements:
  *
  * - Only the owner can call this function
  **/

  function setPhase(DataLibrary.SalePhase phase_)
  external
  onlyOwner {
      phase = phase_;
      emit updatePhase(phase_);
  }

  
  /**
  * @notice returns the starting token identifier
  */
  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  /**
  * @dev mint
  *
  * Emits [Transfer] event.
  *
  * Requirements:
  *
  * - should have a valid coupon if we are ()
  **/

  function mint(
    address to,
    uint16 quantityHq,
    uint16 quantityMuseum,
    uint16 quantityMansion,
    DataLibrary.Coupon memory coupon,
    DataLibrary.CouponType couponType
  ) external
    payable
    whenNotPaused
    verifyCoupon(coupon, couponType)
  {
    // if msg.sender == crossmint address then crossmint use case
    if (msg.sender != to)
      require(msg.sender == DataLibrary.crossMintAddress, "007");

    DataLibrary.InternVar memory internVar;
    internVar.price = msg.value;

    unchecked {
      internVar.quantity = quantityHq + quantityMuseum + quantityMansion;
      internVar.mintsWalletCount = mintsPerAddressCount[to] + internVar.quantity;
    }

    //check total maxSupply mintable 6300
    require(hqIndex + museumIndex + mansionIndex + internVar.quantity < 6300 + 1
      , "006");

    //check total maxSpply mintable per nft type (hq 500, museum 1500, mansion 5000)
    Library.checkSupply(
      hqIndex,
      museumIndex,
      mansionIndex,
      quantityHq,
      quantityMuseum,
      quantityMansion,
      500,
      1500,
      5000
    );

    //phases discount: 01, 02 and 03
    if (phase != DataLibrary.SalePhase.Phase04 && phase != DataLibrary.SalePhase.Phase05) {

       //check matching coupons / phases
      if (phase == DataLibrary.SalePhase.Phase01) {
        require(couponType == DataLibrary.CouponType.HQWL, "001");
      }
      else if (phase == DataLibrary.SalePhase.Phase02) {
        require(couponType == DataLibrary.CouponType.HQWL || couponType == DataLibrary.CouponType.MuseumWL
          , "001");
      }
      else if (phase == DataLibrary.SalePhase.Phase03) {
        require(couponType == DataLibrary.CouponType.HQWL
          || couponType == DataLibrary.CouponType.MuseumWL
          || couponType == DataLibrary.CouponType.MansionWL
          , "001");
      }

      
      require(internVar.mintsWalletCount < 6  //maxMints_BeforePhase04_PerAddress 5
          , "009");
      
      //check maxSpply mintable per nft type and phase (100 hq, 300 meusem, 1000 mansion)
      Library.checkSupply(
        hqIndex,
        museumIndex,
        mansionIndex,
        quantityHq,
        quantityMuseum,
        quantityMansion,
        300,
        810,
        3000
      );

      //define prices for discount phases
      internVar.hqPrice = 0.70 ether;
      internVar.museumPrice = 0.50 ether;
      internVar.mansionPrice = 0.30 ether;
    }
    else {
      //phase 04 private sale
      if (phase == DataLibrary.SalePhase.Phase04) {

        //check matching coupons / phases
        require(couponType == DataLibrary.CouponType.HQWL
          || couponType == DataLibrary.CouponType.MuseumWL
          || couponType == DataLibrary.CouponType.MansionWL
          || couponType == DataLibrary.CouponType.PrivateWL
          , "001");

        unchecked {
          internVar.mintsWalletCount = mintsPerAddressCount[to] + internVar.quantity; 
        }
        if (couponType == DataLibrary.CouponType.PrivateWL)
          require(internVar.mintsWalletCount < 6, "009");
        // no limit
        // require(internVar.mintsWalletCount < 9999 //maxMints_BeforePhase05_PerAddress 10
        //   , "009");

        //check maxSpply mintable per nft type and phase (150 hq, 360 meusem, 1500 mansion)
        Library.checkSupply(
          hqIndex,
          museumIndex,
          mansionIndex,
          quantityHq,
          quantityMuseum,
          quantityMansion,
          285,
          765,
          2850
        );
      }
      //phase 05 public sale
      else if (phase == DataLibrary.SalePhase.Phase05) {

        //check matching coupons / phases
        require(couponType == DataLibrary.CouponType.HQWL
          || couponType == DataLibrary.CouponType.MuseumWL
          || couponType == DataLibrary.CouponType.MansionWL
          || couponType == DataLibrary.CouponType.PrivateWL
          || couponType == DataLibrary.CouponType.PublicWL
          , "001");
        }

        //define prices for private and public phases
        internVar.hqPrice = 1.00 ether;
        internVar.museumPrice = 0.60 ether;
        internVar.mansionPrice = 0.40 ether;
    }

    //can we receive phase != available values? if yes, check validation before mint call
    unchecked {
      internVar.expectedPrice = (quantityHq * internVar.hqPrice) 
        + (quantityMuseum * internVar.museumPrice)
        + (quantityMansion * internVar.mansionPrice);
    }
    require(internVar.expectedPrice < internVar.price + 1, "005");

    //mint Hq
    if (quantityHq != 0) {
      _mint(to, quantityHq);
      for(uint16 i; i < quantityHq; ) {
        tokenIdNftTypes[index + i] = DataLibrary.NftType.Hq;
        unchecked { ++i; }
      }
      hqIndex += quantityHq;
      index += quantityHq;
    }

    //mint Museum
    if (quantityMuseum != 0) {
      _mint(to, quantityMuseum);
      for(uint16 i; i < quantityMuseum; ) {
        tokenIdNftTypes[index + i] = DataLibrary.NftType.Museum;
        unchecked { ++i; }
      }
      unchecked {
        museumIndex += quantityMuseum;
        index += quantityMuseum;
      }
    }

    //mint Mansion
    if (quantityMansion != 0) {
      _mint(to, quantityMansion);
      for(uint16 i; i < quantityMansion; ) {
        tokenIdNftTypes[index + i] = DataLibrary.NftType.Mansion;
        unchecked { ++i; }
      }
      unchecked {
        mansionIndex += quantityMansion;
        index += quantityMansion;
      }
    }
    // increment mint count
    unchecked { mintsPerAddressCount[to] += internVar.quantity; }
  }

  /**
  * @dev freeMint ReservedWL can mint 1 NFT for free
  *
  * Emits a {Transfer} event.
  *
  * Requirements:
  *
  * - Only whitelisted address can call this function
  */

  function freeMint(
    DataLibrary.NftType nftType,
    DataLibrary.Coupon memory coupon,
    DataLibrary.CouponType couponType
  ) external
    whenNotPaused
    verifyCoupon(coupon, couponType)
  {
    // check if msg sender already minted
    require(!isFreeMinted[msg.sender], "010");
    require(couponType == DataLibrary.CouponType.ReservedWL, "001");

    if (nftType == DataLibrary.NftType.Hq) {
      require(freeMintHqCounter > 0, "011");
      _mint(msg.sender, 1);
      tokenIdNftTypes[index] = DataLibrary.NftType.Hq;
      unchecked {
        ++index;
        ++hqIndex;
        --freeMintHqCounter;
      }
    }
    if (nftType == DataLibrary.NftType.Museum) {
      require(freeMintMuseumCounter > 0, "011");
      _mint(msg.sender, 1);
      tokenIdNftTypes[index] = DataLibrary.NftType.Museum;
      unchecked {
        ++index;
        ++museumIndex;
        --freeMintMuseumCounter;
      }
    }
    if (nftType == DataLibrary.NftType.Mansion) {
      require(freeMintMansionCounter > 0, "011");
      _mint(msg.sender, 1);
      tokenIdNftTypes[index] = DataLibrary.NftType.Mansion;
      unchecked {
        ++index;
        ++mansionIndex;
        --freeMintMansionCounter;
      }
    }
    unchecked {
        isFreeMinted[msg.sender] = true;
    } 
  }

  /**
  * @dev giveAway mints 35 HQ, 105 Museums and 350 Mansions once.
  *
  * Emits a {Transfer} event.
  *
  * Requirements:
  *
  * - Only the Landz address can call this function
  */

  function giveAway() external {
    require(msg.sender == DataLibrary.giveAwayAddress, "012");
    require(!isGiveAway, "010");

    //mint 35 hq
    _mint(msg.sender, 35);
    for (uint16 i; i < 35; ) {
      tokenIdNftTypes[index + i] = DataLibrary.NftType.Hq;
      unchecked { ++i; }
    }
    index += 35;
    hqIndex += 35;

    //mint 105 meuseum
    _mint(msg.sender, 105);
    for (uint16 i; i < 105; ) {
      tokenIdNftTypes[index + i] = DataLibrary.NftType.Museum;
      unchecked { ++i; }
    }
    index += 105;
    museumIndex += 105;

    //mint 350 mansion
    _mint(msg.sender, 350);
    for (uint16 i; i < 350; ) {
      tokenIdNftTypes[index + i] = DataLibrary.NftType.Mansion;
      unchecked { ++i; }
    }
    index += 350;
    mansionIndex += 350;
    isGiveAway = true;
  }
  
  /**
  * @notice get the uri to metatada
  * @param tokenId token identifier
  * @return string uri
  */
  function tokenURI(uint256 tokenId)
  public
  view
  override
  returns(string memory) {
    require(_exists(tokenId), "015");
      return bytes(baseURI).length > 0 ?
        string(abi.encodePacked(baseURI, tokenId.toString())) :
        "";
  }

  /**
  * @dev pause() is used to pause contract.
  *
  * Emits a {Paused} event.
  *
  * Requirements:
  *
  * - Only the owner can call this function
  **/

  function pause() external onlyOwner whenNotPaused {
    _pause();
  }

  /**
  * @dev unpause() is used to unpause contract.
  *
  * Emits a {Unpaused} event.
  *
  * Requirements:
  *
  * - Only the owner can call this function
  **/

  function unpause() external onlyOwner whenPaused {
    _unpause();
  }

  /**
  * @dev withdraw is used to withdraw payment from contract.
  *
  * Emits a {WithdrawnPayment} event.
  *
  * Requirements:
  *
  * - Only the owner can call this function
  **/

  function withdraw() external {
    require(msg.sender == DataLibrary.landzAddress || msg.sender == DataLibrary.advisorA, "012");
    uint256 balanceAdvisorA;
    uint256 balanceAdvisorB;
    uint256 balanceAdvisorC;
    uint256 balanceAdvisorD;
    unchecked {
      balanceAdvisorA = address(this).balance * 1000 / 10000;
      balanceAdvisorB = address(this).balance * 1750 / 10000;
      balanceAdvisorC = address(this).balance * 500 / 10000;
      balanceAdvisorD = address(this).balance * 400 / 10000;
    }
    (bool successA, ) = payable(DataLibrary.advisorA).call{ value: balanceAdvisorA }("");
    (bool successB, ) = payable(DataLibrary.advisorB).call{ value: balanceAdvisorB }("");
    (bool successC, ) = payable(DataLibrary.advisorC).call{ value: balanceAdvisorC }("");
    (bool successD, ) = payable(DataLibrary.advisorD).call{ value: balanceAdvisorD }("");
    require(successA && successB && successC && successD, "013");
    uint256 balanceLandz = address(this).balance;
    (bool success, ) = payable(DataLibrary.landzAddress).call{ value: balanceLandz }("");
    require(success, "014");
    emit WithdrawnPayment(balanceLandz, balanceAdvisorA, balanceAdvisorB, balanceAdvisorC, balanceAdvisorD);
  }

  /**
  * @dev setBaseUri updates the new token URI in contract.
  *
  * Emits a {NewURI} event.
  *
  * Requirements:
  *
  * - Only owner of contract can call this function
  **/

  function setBaseUri(string memory uri)
  external
  onlyOwner {
      baseURI = uri;
      emit NewURI(uri);
  }

  /**
  * @dev getNftType retreives Nft type by token identifier.
  **/
  function getNftType(uint16 _tokenId) external view returns(DataLibrary.NftType) {
    return tokenIdNftTypes[_tokenId];
  }

  // /// @notice get the available supply for HQ

  // function getAvailableHqFreeMint() external view returns(uint256) {
  //   return freeMintHqCounter;
  // }

  // /// @notice get the available supply for Museum

  // function getAvailableMuseumFreeMint() external view returns(uint256) {
  //   return freeMintMuseumCounter;
  // }

  // /// @notice get the available supply for Mansion

  // function getAvailableMansionFreeMint() external view returns(uint256) {
  //   return freeMintMansionCounter;
  // }

  // /// @notice return the adminSigner address

  // function getAdminSigner() external pure returns(address) {
  //   return DataLibrary._adminSigner;
  // }

  // /// @notice return the treasury address

  // function getlandzAddress() external pure returns(address) {
  //   return DataLibrary.landzAddress;
  // }
}