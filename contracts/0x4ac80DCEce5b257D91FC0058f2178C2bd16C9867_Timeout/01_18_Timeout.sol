// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { Ownable } from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import { ReentrancyGuard } from "../lib/openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
import "../lib/openzeppelin-contracts/contracts/token/common/ERC2981.sol";
import "../lib/ERC721A/contracts/ERC721A.sol";
import "../lib/ERC721A/contracts/extensions/ERC721AQueryable.sol";
import { DataLibrarry } from "./lib/DataLibrarry.sol";
import { FunctionLib } from "./lib/FunctionLib.sol";
import { ITimeout } from "./ITimeout.sol";
import { Address } from "../lib/openzeppelin-contracts/contracts/utils/Address.sol";
import { Strings } from "../lib/openzeppelin-contracts/contracts/utils/Strings.sol";
import { Base64 } from "../lib/openzeppelin-contracts/contracts/utils/Base64.sol";

/**
* @title Timeout
* @author chixx.eth & @mouradmki
* @notice ERC721A Royalties With fusion, claim for the genesis holder
*/
contract Timeout is ITimeout, ERC721A, ERC721AQueryable, Ownable, ERC2981, ReentrancyGuard {
  using Strings for uint256;
  uint256 public gameFunds;
  uint256 public claimFunds;

  uint16 public constant maxSupplyToMint = 8192;
  uint16 public constant supplyPremint = 2505;

  uint8 private constant maxMintPerWallet_phase03 = 2;
  uint8 private constant maxMintPerWallet_phase04 = 5;

  uint16 public indexMint = 2505;

  uint16 private indexEvolution1Blue;
  uint16 private indexEvolution1Pink;
  uint16 private indexEvolution2Blue;
  uint16 private indexEvolution2Pink;
  uint16 private indexEvolution3Blue;
  uint16 private indexEvolution3Pink;
  uint16 private indexEvolution4Blue;
  uint16 private indexEvolution4Pink;
  uint16 private indexEvolution5Blue;
  uint16 private indexEvolution5Pink;
  uint16 private indexEvolution6Blue;
  uint16 private indexEvolution6Pink;

  uint16 private constant maxSupplyEvolution1PinkAndBlue = 2048;
  uint16 private constant maxSupplyEvolution2PinkAndBlue = 1024;
  uint16 private constant maxSupplyEvolution3PinkAndBlue = 512;
  uint16 private constant maxSupplyEvolution4PinkAndBlue = 256;
  uint16 private constant maxSupplyEvolution5PinkAndBlue = 128;
  uint16 private constant maxSupplyEvolution6PinkAndBlue = 64;

  uint16 private constant portionForClaim = 1294;

  uint16 private index = 2506;
  uint16 private maxSupplyPrivateSale = 1901;
  uint16 private constant maxSupplyPremint = 2505;

  uint16 public phaseForClaim;

  address private WhiteListSigner = 0x99A7130dc775dB71E5252dE59F0f156DF1B96d89;

  string public baseURI = "ipfs://QmaCF1nHa7imHxox33rhXw6mMDu69PUWncpCVK7H1Kmc6B/";

  bool private isPremint;

  DataLibrarry.SalePhase public phase = DataLibrarry.SalePhase.Phase01;

  mapping(uint256 => DataLibrarry.Metadata) private metadatas;
  /**
  * @notice mapping for know for each phase if the tokenId have claim
  * @dev
  * {
  *   uint256 => phase
  *   addres => user address
  *   bool => isClaimed
  * }
  */
  mapping(uint256 => mapping(address => bool)) public isClaimed;
  mapping(address =>  bool) public isFreeMinted;
  mapping(address => uint16) private mintCountPhase03;
  mapping(address => uint16) private mintCountPhase04;

  event NewURI(string newURI, address updatedBy);
  event updatePhase(DataLibrarry.SalePhase phase);
  event updatePhaseForClaim(uint16 phase);
  event Receive(address sender, uint256 amount);
  event ClaimGame(uint256 tokenIdEvo7, address user, uint256 amountClaim);
  event Claim(address user, uint256 amount, uint16 phase);
  event Withdraw(uint256 amount);
  event WithdrawGameFunds(uint256 amount);
  event WithdrawClaimFunds(uint256 amount);

  constructor() ERC721A("TimeoutOrigin", "TOO") {
    _setDefaultRoyalty(address(this), 1500);
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC2981, IERC721A, ERC721A) returns (bool) {
    return interfaceId == type(IERC2981).interfaceId // interface ID for royalties
      || interfaceId == type(IERC165).interfaceId
      || interfaceId == 0x80ac58cd // interface ID for ERC721.
      || interfaceId == 0x5b5e139f // interface ID for ERC721Metadata.
      || super.supportsInterface(interfaceId);
  }

  modifier onlyPhase05() {
    require(phase == DataLibrarry.SalePhase.Phase05, "Invalid phase");
    _;
  }

  /**
  * @notice receive eth for royalties.
  */
  receive() external payable {
    uint256 value = msg.value;
    if(msg.sender == owner())
      gameFunds += value;
    else {
      gameFunds += value * 75 / 100;
      claimFunds += value * 25 / 100;
    }
    emit Receive(msg.sender, value);
  }

  /**
  * @notice withdraw the funds for the game.
  *
  * Requirements:
  *
  * - Only owner of contract can call this function
  */
  function withdrawGameFunds() external onlyOwner {
    (bool success, ) = payable(msg.sender).call{value: gameFunds}("");
    if (!success) revert FailToWithdraw();
    emit WithdrawGameFunds(gameFunds);
  }

  /**
  * @notice withdraw the funds for the claim.
  *
  * Requirements:
  *
  * - Only owner of contract can call this function
  */
  function withdrawClaimFunds() external onlyOwner {
    (bool success, ) = payable(msg.sender).call{value: claimFunds}("");
    if (!success) revert FailToWithdraw();
    emit WithdrawClaimFunds(claimFunds);
  }

  /**
  * @notice Returns the starting token ID.
  */
  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  /**
  * @notice set the phase for mint
  */
  function setPhase(DataLibrarry.SalePhase _phase)
    external
    onlyOwner
  {
    phase = _phase;
    emit updatePhase(_phase);
  }

  /**
  * @notice set the phase for claim
  */
  function setPhaseForClaim(uint8 newPhase)
    external
    onlyOwner
  {
    phaseForClaim = newPhase;
    emit updatePhaseForClaim(newPhase);
  }

  /**
  * @notice get if msg.sender has claim in the current phase
  */
  function hasClaimed() external view returns (bool) {
    return isClaimed[phaseForClaim][msg.sender];
  }

  /**
  * @notice updates the new token URI in contract.
  *
  * Emits a {NewURI} event.
  *
  * Requirements:
  *
  * - Only owner of contract can call this function
  **/
  function setBaseUri(string memory uri)
    external
    onlyOwner
  {
    baseURI = uri;
    emit NewURI(uri, msg.sender);
  }

  /**
  * @dev See {IERC721Metadata-tokenURI}.
  */
  function tokenURI(uint256 tokenId)
    public
    view
    override(ERC721A,IERC721A)
    returns(string memory)
  {
    if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
    DataLibrarry.Metadata memory datas = getMetadatas(tokenId);

    bytes memory json1 = abi.encodePacked(
      '{',
        '"name": "TimeOutOrigin #',tokenId.toString(),'"',',',
        '"image": ',
        '"',
        baseURI,
        uint256(datas.evolution).toString(),
        '-',
        uint256(datas.types).toString(),
        '.jpeg",'
    );
    bytes memory json = abi.encodePacked(
      json1,
      '"attributes": [{"trait_type": "Evolution","value": "',
      uint256(datas.evolution).toString(), '"},',
      '{"trait_type": "type","value": "',
      datas.types == 0 ? "B" : "A", '"}]',
      '}'
    );
    return string(
      abi.encodePacked(
        "data:application/json;base64,",
        Base64.encode(json)
      )
    );
  }

  /**
  * @notice premint mint 2505 for the owner.
  *
  * Requirements:
  *
  * - Only owner of contract can call this function
  **/
  function premint() external onlyOwner {
    if (isPremint) revert AlreadyUsePremint();
    if (phase != DataLibrarry.SalePhase.Phase01) revert InvalidPhase();
    _mint(msg.sender, supplyPremint);
    isPremint = true;
  }

  /**
  * @notice privatesalesmint mint on private sale.
  *
  * Requirements:
  *
  * - Only whitelisted address can mint
  **/
  function privatesalesmint(
    DataLibrarry.Coupon memory coupon,
    DataLibrarry.CouponType couponType,
    DataLibrarry.CouponTypeCount memory count
  )
    external
  {
    if(phase != DataLibrarry.SalePhase.Phase02) revert InvalidPhase();
    if(isFreeMinted[msg.sender] == true) revert AlreadyUsePrivateSalesMint();
    FunctionLib.verifyCoupon(WhiteListSigner, coupon, couponType, count);
    if (couponType == DataLibrarry.CouponType.WhiteListSales)
      revert InvalidWhitelist();
    uint16 quantity;
    unchecked {
      quantity =
        (count.BasicCount * 2)
        + (count.UltrarareCount * 3)
        + (count.LegendaireCount * 4)
        + (count.eggCount * 2);
    }
    if (indexMint + quantity > maxSupplyPrivateSale + maxSupplyPremint) revert MaxSupplyPrivateSaleReach();
    _mint(msg.sender, quantity);
    unchecked {
      index += quantity;
      indexMint += quantity;
      isFreeMinted[msg.sender] = true;
    }
  }

  /**
  * @notice whitelistsalesmint mint on whitelist sale.
  *
  * Requirements:
  *
  * - Only whitelisted address can mint
  **/
  function whitelistsalesmint(
    uint16 quantityToMint,
    DataLibrarry.Coupon memory coupon,
    DataLibrarry.CouponType couponType,
    DataLibrarry.CouponTypeCount memory count
  )
    external
  {
    if(phase != DataLibrarry.SalePhase.Phase03) revert InvalidPhase();
    FunctionLib.verifyCoupon(WhiteListSigner, coupon, couponType, count);
    if (mintCountPhase03[msg.sender] + quantityToMint > maxMintPerWallet_phase03)
      revert InvalidQuantity();
    if (indexMint + quantityToMint > maxSupplyToMint) revert MaxSupplyReach();
    _mint(msg.sender, quantityToMint);
    unchecked {
      mintCountPhase03[msg.sender] += quantityToMint;
      index += quantityToMint;
      indexMint += quantityToMint;
    }
  }

  /**
  * @notice mint on public sale.
  **/
  function mint(
    uint8 quantityToMint
  )
    external
  {
    if(phase !=  DataLibrarry.SalePhase.Phase04) revert InvalidPhase();
    if (mintCountPhase04[msg.sender] + quantityToMint > maxMintPerWallet_phase04
    ) revert InvalidQuantity();
    if (indexMint + quantityToMint > maxSupplyToMint) revert MaxSupplyReach();
    _mint(msg.sender, quantityToMint);
    unchecked { 
      mintCountPhase04[msg.sender] += quantityToMint;
      index += quantityToMint;
      indexMint += quantityToMint;
    }
  }

  /**
  * @notice get the metadata from a tokenId
  * @return data struct contain the metadata
  */
  function getMetadatas(uint256 tokenId) public view returns(DataLibrarry.Metadata memory data) {
    if (!_exists(tokenId)) revert QueryForNonExistantTokenId();
    if (metadatas[tokenId].evolution == 0) {
      if (tokenId % 2 == 0) {
        data.types = 0;
      } else {
        data.types = 1;
      }
      return data;
    }
    return metadatas[tokenId];
  }

  /**
  * @notice clacule a pseudo random number
  * @return uint8 0 or 1
  */
  function random() public view returns(uint8) {
    return
      uint8(uint256(keccak256(abi.encodePacked(
        block.difficulty, block.timestamp
      ))) % 2);
  }

  /**
  * @notice fusion 2 evo0 for evo1.
  *
  * Requirements:
  *
  * - need evo0 blue and evo0 pink
  **/
  function fusionEvo0(uint256 tokenId0, uint256 tokenId1) external onlyPhase05 {
    if (!_exists(tokenId0) || !_exists(tokenId1)) revert QueryForNonExistantTokenId();
    if (ownerOf(tokenId0) != msg.sender || ownerOf(tokenId1) != msg.sender)
      revert CallerNotOwnerOfTokenId();
    DataLibrarry.Metadata memory metadata;
    uint8 _random = random();
    if (metadatas[tokenId0].evolution != 0 || metadatas[tokenId1].evolution != 0)
      revert InvalidTokenIdsForFusion();
    else {
      uint8 metadata0 = uint8(tokenId0 % 2);
      uint8 metadata1 = uint8(tokenId1 % 2);
      if ((metadata0 == metadata1))
        revert InvalidTokenIdsForFusion();
      _random = FunctionLib.logicRandomEvo(
        _random, indexEvolution1Blue,
        indexEvolution1Pink,
        maxSupplyEvolution1PinkAndBlue
      );
      if (_random == 0) {
        metadata.types = 0;
        unchecked { ++indexEvolution1Blue; }
      }
      else {
        metadata.types = 1;
        unchecked { ++indexEvolution1Pink; }
      }
      metadata.evolution = 1;
      metadatas[index] = metadata;
      _burn(tokenId0);
      _burn(tokenId1);
      _mint(msg.sender, 1);
      unchecked { ++index; }
    }
  }

  /**
  * @notice fusion 2 evo1 for evo2.
  *
  * Requirements:
  *
  * - need evo1 blue and evo1 pink
  **/
  function fusionEvo1(uint256 tokenId0, uint256 tokenId1) external onlyPhase05 {
    if (!_exists(tokenId0) || !_exists(tokenId1)) revert QueryForNonExistantTokenId();
    if (ownerOf(tokenId0) != msg.sender || ownerOf(tokenId1) != msg.sender)
      revert CallerNotOwnerOfTokenId();
    DataLibrarry.Metadata memory metadata;
    uint8 _random = random();
    if ((metadatas[tokenId0].types == 0 && metadatas[tokenId1].types == 0)
      || (metadatas[tokenId0].types == 1 && metadatas[tokenId1].types == 1))
      revert InvalidTokenIdsForFusion();
    if (metadatas[tokenId0].evolution != 1 || metadatas[tokenId1].evolution != 1)
      revert InvalidTokenIdsForFusion();
    else {
      _random = FunctionLib.logicRandomEvo(
        _random, indexEvolution2Blue,
        indexEvolution2Pink,
        maxSupplyEvolution2PinkAndBlue
      );
      if (_random == 0) {
        metadata.types = 0;
        unchecked { ++indexEvolution2Blue; }
      }
      else {
        metadata.types = 1;
        unchecked { ++indexEvolution2Pink; }
      }
      metadata.evolution = 2;
      metadatas[index] = metadata;
      _burn(tokenId0);
      _burn(tokenId1);
      _mint(msg.sender, 1);
      unchecked { ++index; }
    }
  }

  /**
  * @notice fusion 2 evo2 for evo3.
  *
  * Requirements:
  *
  * - need evo2 blue and evo1 pink
  **/
  function fusionEvo2(uint256 tokenId0, uint256 tokenId1) external onlyPhase05 {
    if (!_exists(tokenId0) || !_exists(tokenId1)) revert QueryForNonExistantTokenId();
    if (ownerOf(tokenId0) != msg.sender || ownerOf(tokenId1) != msg.sender)
      revert CallerNotOwnerOfTokenId();
    DataLibrarry.Metadata memory metadata;
    uint8 _random = random();
    if ((metadatas[tokenId0].types == 0 && metadatas[tokenId1].types == 0)
      || (metadatas[tokenId0].types == 1 && metadatas[tokenId1].types == 1))
      revert InvalidTokenIdsForFusion();
    if (metadatas[tokenId0].evolution != 2 || metadatas[tokenId1].evolution != 2)
      revert InvalidTokenIdsForFusion();
    else {
      _random = FunctionLib.logicRandomEvo(
          _random,
          indexEvolution3Blue,
          indexEvolution3Pink,
          maxSupplyEvolution3PinkAndBlue
        );
        if (_random == 0) {
          metadata.types = 0;
          unchecked { ++indexEvolution3Blue; }
        }
        else {
          metadata.types = 1;
          unchecked { ++indexEvolution3Pink; }
        }
        metadata.evolution = 3;
        metadatas[index] = metadata;
        _burn(tokenId0);
        _burn(tokenId1);
        _mint(msg.sender, 1);
        unchecked { ++index; }
    }
  }

  /**
  * @notice fusion 2 evo3 for evo4.
  *
  * Requirements:
  *
  * - need evo3 blue and evo3 pink
  **/
  function fusionEvo3(uint256 tokenId0, uint256 tokenId1) external onlyPhase05{
    if (!_exists(tokenId0) || !_exists(tokenId1)) revert QueryForNonExistantTokenId();
    if (ownerOf(tokenId0) != msg.sender || ownerOf(tokenId1) != msg.sender)
      revert CallerNotOwnerOfTokenId();
    DataLibrarry.Metadata memory metadata;
    uint8 _random = random();
    if ((metadatas[tokenId0].types == 0 && metadatas[tokenId1].types == 0)
      || (metadatas[tokenId0].types == 1 && metadatas[tokenId1].types == 1))
      revert InvalidTokenIdsForFusion();
    if (metadatas[tokenId0].evolution != 3 || metadatas[tokenId1].evolution != 3)
      revert InvalidTokenIdsForFusion();
    else {
      _random = FunctionLib.logicRandomEvo(
        _random,
        indexEvolution4Blue,
        indexEvolution4Pink,
        maxSupplyEvolution4PinkAndBlue
      );
      if (_random == 0) {
        metadata.types = 0;
        unchecked { ++indexEvolution4Blue; }
      }
      else {
        metadata.types = 1;
        unchecked { ++indexEvolution4Pink; }
      }
      metadata.evolution = 4;
      metadatas[index] = metadata;
      _burn(tokenId0);
      _burn(tokenId1);
      _mint(msg.sender, 1);
      unchecked { ++index; }
    }
  }

  /**
  * @notice fusion 2 evo4 for evo5.
  *
  * Requirements:
  *
  * - need evo4 blue and evo4 pink
  **/
  function fusionEvo4(uint256 tokenId0, uint256 tokenId1) external onlyPhase05{
    if (!_exists(tokenId0) || !_exists(tokenId1)) revert QueryForNonExistantTokenId();
    if (ownerOf(tokenId0) != msg.sender || ownerOf(tokenId1) != msg.sender)
      revert CallerNotOwnerOfTokenId();
    DataLibrarry.Metadata memory metadata;
    uint8 _random = random();
    if ((metadatas[tokenId0].types == 0 && metadatas[tokenId1].types == 0)
      || (metadatas[tokenId0].types == 1 && metadatas[tokenId1].types == 1))
      revert InvalidTokenIdsForFusion();
    if (metadatas[tokenId0].evolution != 4 || metadatas[tokenId1].evolution != 4)
      revert InvalidTokenIdsForFusion();
    else {
      _random = FunctionLib.logicRandomEvo(
        _random,
        indexEvolution5Blue,
        indexEvolution5Pink,
        maxSupplyEvolution5PinkAndBlue
      );
      if (_random == 0) {
        metadata.types = 0;
        unchecked { ++indexEvolution5Blue; }
      }
      else {
        metadata.types = 1;
        unchecked { ++indexEvolution5Pink; }
      }
      metadata.evolution = 5;
      metadatas[index] = metadata;
      _burn(tokenId0);
      _burn(tokenId1);
      _mint(msg.sender, 1);
      unchecked { ++index; }
    }
  }

  /**
  * @notice fusion 2 evo5 for evo6.
  *
  * Requirements:
  *
  * - need evo5 blue and evo5 pink
  **/
  function fusionEvo5(uint256 tokenId0, uint256 tokenId1) external onlyPhase05{
    if (!_exists(tokenId0) || !_exists(tokenId1)) revert QueryForNonExistantTokenId();
    if (ownerOf(tokenId0) != msg.sender || ownerOf(tokenId1) != msg.sender)
      revert CallerNotOwnerOfTokenId();
    DataLibrarry.Metadata memory metadata;
    uint8 _random = random();
    if ((metadatas[tokenId0].types == 0 && metadatas[tokenId1].types == 0)
      || (metadatas[tokenId0].types == 1 && metadatas[tokenId1].types == 1))
      revert InvalidTokenIdsForFusion();
    if (metadatas[tokenId0].evolution != 5 || metadatas[tokenId1].evolution != 5)
      revert InvalidTokenIdsForFusion();
    else {
      _random = FunctionLib.logicRandomEvo(
        _random,
        indexEvolution6Blue,
        indexEvolution6Pink,
        maxSupplyEvolution6PinkAndBlue
      );
      if (_random == 0) {
        metadata.types = 0;
        unchecked { ++indexEvolution6Blue; }
      }
      else {
        metadata.types = 1;
        unchecked { ++indexEvolution6Pink; }
      }
      metadata.evolution = 6;
      metadatas[index] = metadata;
      _burn(tokenId0);
      _burn(tokenId1);
      _mint(msg.sender, 1);
      unchecked { ++index; }
    }
  }

  /**
  * @notice fusion 2 evo6 for evo7.
  *
  * Requirements:
  *
  * - need evo6 blue and evo6 pink
  **/
  function fusionEvo6(uint256 tokenId0, uint256 tokenId1) external onlyPhase05 {
    if (!_exists(tokenId0) || !_exists(tokenId1)) revert QueryForNonExistantTokenId();
    if (ownerOf(tokenId0) != msg.sender || ownerOf(tokenId1) != msg.sender)
      revert CallerNotOwnerOfTokenId();
    DataLibrarry.Metadata memory metadata;
    if ((metadatas[tokenId0].types == 0 && metadatas[tokenId1].types == 0)
      || (metadatas[tokenId0].types == 1 && metadatas[tokenId1].types == 1))
      revert InvalidTokenIdsForFusion();
    if (metadatas[tokenId0].evolution != 6 || metadatas[tokenId1].evolution != 6)
      revert InvalidTokenIdsForFusion();
    else {
      metadata.evolution = 7;
      metadata.types = 3;
      metadatas[index] = metadata;
      _burn(tokenId0);
      _burn(tokenId1);
      _mint(msg.sender, 1);
      unchecked { ++index; }
    }
   }

  /**
  * @notice claim 50% of the game funds.
  *
  * Requirements:
  *
  * - need evo7
  **/
  function claimGame(uint256 tokenIdEvo7) external nonReentrant() {
    if (Address.isContract(msg.sender)) revert SenderIsContract();
    if (!_exists(tokenIdEvo7)) revert QueryForNonExistantTokenId();
    if (ownerOf(tokenIdEvo7) != msg.sender) revert CallerNotOwnerOfTokenId();
    if (metadatas[tokenIdEvo7].evolution != 7) revert InvalidEvolution();
    gameFunds = gameFunds / 2;
    (bool success, ) = payable(address(msg.sender)).call{value: gameFunds}("");
    if (!success) revert FailToTransferGameFunds();
    _burn(tokenIdEvo7);
    emit ClaimGame(tokenIdEvo7, msg.sender, gameFunds);
  }

  /**
  * @notice claim for genesis holder.
  *
  * Requirements:
  *
  * - need to be whitelisted, snapchot
  **/
  function claim(
    DataLibrarry.Coupon memory coupon,
    DataLibrarry.CouponClaim memory couponClaim
  )
    external
    nonReentrant()
  {
    if (Address.isContract(msg.sender)) revert SenderIsContract();
    if (msg.sender != couponClaim.user) revert InvalidUser();
    if (isClaimed[phaseForClaim][msg.sender]) revert UserAlreadyClaimForThisPhase();
    if (couponClaim.phase != phaseForClaim) revert InvalidPhase();
    FunctionLib.verifyCouponForClaim(WhiteListSigner, coupon, couponClaim);
    uint256 portion = (couponClaim.legCount * 10)
      + (couponClaim.urEggCount * 6)
      + (couponClaim.urCount * 5)
      + (couponClaim.basicEggCount * 2)
      + (couponClaim.basicCount * 1);
    uint256 totalClaim = claimFunds / portionForClaim * portion;
    (bool success, ) = payable(address(msg.sender)).call{value: totalClaim}("");
    if (!success) revert FailToTransferClaimFunds();
    isClaimed[phaseForClaim][msg.sender] = true;
    emit Claim(msg.sender, totalClaim, phaseForClaim);
  }
}