// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import {EIP712} from '@openzeppelin/contracts/utils/cryptography/EIP712.sol';
import {ERC1155} from '@openzeppelin/contracts/token/ERC1155/ERC1155.sol';

import {Strings} from '@openzeppelin/contracts/utils/Strings.sol';
import {SignatureChecker} from '@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol';
import {ECDSA} from '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import {BitMaps} from '@openzeppelin/contracts/utils/structs/BitMaps.sol';
import {ReentrancyGuard} from '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import {Pausable} from '@openzeppelin/contracts/security/Pausable.sol';
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {IOldeusAuction, Stats} from './interfaces/OldeusAuction.sol';
import {UpdatableOperatorFilterer} from 'operator-filter-registry/src/UpdatableOperatorFilterer.sol';

bytes32 constant CLAIM_HASH = keccak256('Claim(address claimer,address issuer,uint256 refundAmount,uint256[] tokenIds)');

bytes32 constant RESERVE_HASH = keccak256('Reserve(address minter,address issuer,uint256 maxQuantity,bool isAllowlist)');

struct Reservation {
  uint16 count;
  bool claimed;
}

contract Oldeus1155 is ERC1155, EIP712, Ownable, Pausable, ReentrancyGuard, UpdatableOperatorFilterer {
  using ECDSA for bytes32;
  using Strings for uint256;
  using BitMaps for BitMaps.BitMap;

  uint16 public maxSupply;
  uint16 public auctionSupply;
  uint16 public reservedSupply;
  uint64 public price;
  uint64 public allowlistPrice;

  bool public reserveOpen;
  bool public claimOpen;

  address public auctionContract;
  address public mintContract;
  address public issuer;
  mapping(address => Reservation) public reservations;
  BitMaps.BitMap private _tokenIds;

  event Reserve(address indexed reserver, uint256 indexed quantity);
  event Claim(address indexed claimer, uint256 indexed quantity, uint256 indexed refund);

  constructor(
    string memory name_,
    string memory version_,
    string memory uri_,
    address issuer_,
    address auctionContract_,
    uint16 maxSupply_,
    uint16 auctionSupply_,
    address registry_,
    address subscription_
  ) EIP712(name_, version_) ERC1155(uri_) UpdatableOperatorFilterer(registry_, subscription_, true) {
    issuer = issuer_;
    auctionContract = auctionContract_;
    maxSupply = maxSupply_;
    auctionSupply = auctionSupply_;
  }

  function reserve(
    uint256 quantity,
    uint256 maxQuantity,
    bool isAllowlist,
    bytes calldata signature
  ) external payable nonReentrant whenNotPaused {
    require(price > 0 && allowlistPrice > 0, 'reserve: price not set');
    require(reserveOpen, 'reserve: not open');
    require(_safeCheckReservation(maxQuantity, isAllowlist, signature), 'reserve: invalid signature');
    require(quantity + reservedSupply + auctionSupply <= maxSupply, 'reserve: insufficient supply');
    require(reservations[msg.sender].count + quantity <= maxQuantity, 'reserve: insufficient spots');
    require(msg.value >= quantity * (isAllowlist ? allowlistPrice : price), 'reserve: insufficient funds');

    reservations[msg.sender].count += uint16(quantity);
    reservedSupply += uint16(quantity);
    emit Reserve(msg.sender, quantity);
  }

  function claim(uint256[] calldata tokenIds, bytes calldata signature) external nonReentrant whenNotPaused {
    require(claimOpen, 'claim: not open');
    require(!_exists(tokenIds), 'claim: id taken');
    Reservation storage reservation = reservations[msg.sender];
    require(!reservation.claimed, 'claim: already claimed');
    uint256 refundAmount;
    if (IOldeusAuction(auctionContract).exists(msg.sender)) {
      Stats memory stats = IOldeusAuction(auctionContract).stats(msg.sender);
      if (!stats.refundClaimed) {
        uint256 auctionPayment = price * (tokenIds.length - reservation.count);
        require(stats.bidAmount >= auctionPayment, 'claim: insufficient auction bid');
        refundAmount = stats.bidAmount - auctionPayment;
        require(tokenIds.length == reservation.count + auctionPayment / price, 'claim: must claim all tokens');
      }
    }
    if (refundAmount == 0) {
      require(reservation.count == tokenIds.length, 'claim: must claim all tokens');
    }

    _safeCheckClaim(refundAmount, tokenIds, signature);
    uint256[] memory quantities = new uint256[](tokenIds.length);
    for (uint256 i = 0; i < tokenIds.length; ++i) {
      quantities[i] = 1;
      _tokenIds.set(tokenIds[i]);
    }
    _mintBatch(msg.sender, tokenIds, quantities, '');
    if (refundAmount > 0) {
      IOldeusAuction(auctionContract).refund(payable(msg.sender), refundAmount);
    }
    emit Claim(msg.sender, tokenIds.length, refundAmount);
  }

  function burnMint(address from, uint256[] calldata ids) external nonReentrant {
    require(msg.sender == mintContract, 'burnMint: sender not mintContract');
    uint256[] memory quantities = new uint256[](ids.length);
    for (uint256 i = 0; i < quantities.length; ++i) {
      quantities[i] = 1;
    }
    _burnBatch(from, ids, quantities);
  }

  function uri(uint256 id) public view override returns (string memory) {
    require(_tokenIds.get(id), "uri: token doesn't exist");
    return string.concat(super.uri(id), id.toString());
  }

  function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
    super.setApprovalForAll(operator, approved);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    uint256 amount,
    bytes memory data
  ) public override onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId, amount, data);
  }

  function safeBatchTransferFrom(
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) public virtual override onlyAllowedOperator(from) {
    super.safeBatchTransferFrom(from, to, ids, amounts, data);
  }

  function owner() public view override(Ownable, UpdatableOperatorFilterer) returns (address) {
    return Ownable.owner();
  }

  function setAuctionSupply(uint16 auctionSupply_) external onlyOwner {
    auctionSupply = auctionSupply_;
  }

  function setAuctionContract(address auctionContract_) external onlyOwner {
    require(auctionContract_ != address(0), "setAuctionContract: address can't be zero address");
    auctionContract = auctionContract_;
  }

  function setMintContract(address mintContract_) external onlyOwner {
    require(mintContract_ != address(0), "setMintContract: address can't be zero address");
    mintContract = mintContract_;
  }

  function setReserveOpen(bool reserveOpen_) external onlyOwner {
    reserveOpen = reserveOpen_;
  }

  function setClaimOpen(bool claimOpen_) external onlyOwner {
    claimOpen = claimOpen_;
  }

  function setPrices(uint64 price_, uint64 allowlistPrice_) external onlyOwner {
    price = price_;
    allowlistPrice = allowlistPrice_;
  }

  function withdraw(address payable to) external onlyOwner {
    require(to != address(0), "withdraw: address can't be zero address");

    address contractAddress = address(this);
    to.transfer(contractAddress.balance);
  }

  function devMint(address[] calldata recipients, uint256[] calldata quantities, uint256[] calldata tokenIds) external onlyOwner {
    require(recipients.length == quantities.length, 'devMint: array lengths must match');
    require(!_exists(tokenIds), 'devMint: id taken');
    uint256 j;
    uint256 total;
    uint256[] memory quantities_;
    for (uint256 i = 0; i < recipients.length; ++i) {
      require(recipients[i] != address(0), "devMint: address can't be zero address");
      j = quantities[i];
      quantities_ = _fillArray(j, 1);
      _mintBatch(recipients[i], tokenIds[total:total + j], quantities_, '');
      for (uint256 k = 0; k < j; ++k) {
        _tokenIds.set(tokenIds[total:total + j][k]);
      }
      total += j;
    }
    require(total == tokenIds.length, 'devMint: mint count misaligned');
    reservedSupply += uint16(total);
  }

  function _fillArray(uint256 length, uint256 val) internal pure returns (uint256[] memory) {
    uint256[] memory quantities = new uint256[](length);
    for (uint256 i = 0; i < length; ++i) {
      quantities[i] = val;
    }
    return quantities;
  }

  function _safeCheckReservation(uint256 maxQuantity, bool isAllowlist, bytes calldata signature) internal view returns (bool) {
    bytes32 reservationHash = _getHash(msg.sender, issuer, maxQuantity, isAllowlist);
    require(SignatureChecker.isValidSignatureNow(issuer, reservationHash, signature), '_safeCheckReservation: invalid signature');
    return true;
  }

  function _safeCheckClaim(uint256 refundAmount, uint256[] calldata tokenIds, bytes calldata signature) internal view returns (bool) {
    bytes32 claimHash = _getHash(msg.sender, issuer, refundAmount, tokenIds);
    require(SignatureChecker.isValidSignatureNow(issuer, claimHash, signature), '_safeCheckClaim: invalid signature');
    return true;
  }

  function _getHash(address minter, address issuer, uint256 maxQuantity, bool isAllowlist) internal view returns (bytes32) {
    bytes32 structHash = keccak256(abi.encode(RESERVE_HASH, minter, issuer, maxQuantity, isAllowlist));

    return _hashTypedDataV4(structHash);
  }

  function _exists(uint256[] calldata tokenIds) internal view returns (bool) {
    for (uint256 i = 0; i < tokenIds.length; ++i) {
      if (_tokenIds.get(tokenIds[i])) {
        return true;
      }
    }
    return false;
  }

  function _getHash(address claimer, address issuer, uint256 refundAmount, uint256[] calldata tokenIds) internal view returns (bytes32) {
    bytes32 structHash = keccak256(abi.encode(CLAIM_HASH, claimer, issuer, refundAmount, keccak256(abi.encodePacked(tokenIds))));

    return _hashTypedDataV4(structHash);
  }

  function setURI(string calldata uri) external onlyOwner {
    _setURI(uri);
  }
}