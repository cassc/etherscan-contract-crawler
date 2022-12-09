// SPDX-License-Identifier: Apache-2.0
// @Kairos V1.0

pragma solidity ^0.8.11;
import "../lib/Constants.sol";
import "../lib/CommonErrors.sol";
import "../lib/AuctionErrors.sol";

import "../extension/interface/IPlatformFee.sol";
import "../extension/interface/IPrimarySale.sol";

// Access Control + security
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

// Signature utils
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";

import { ITokenERC721 } from "../interfaces/token/ITokenERC721.sol";

struct BidRequest {
  address payable account;
  bytes32 auctionId;
  uint256 amount;
}

struct Bid {
  address payable account;
  uint256 amount;
  bool isFiat;
}

struct Auction {
  bytes32 auctionId;
  bool valid;
  Bid winningBid;
}

contract AuctionHouse is Initializable,
                         IPlatformFee,
                         IPrimarySale,
                         EIP712Upgradeable,
                         AccessControlEnumerableUpgradeable {

  using ECDSAUpgradeable for bytes32;

  bytes32 private constant TYPEHASH =
    keccak256(
        "BidRequest(address account,bytes32 auctionId,uint256 amount)"
    );

  /// @dev the wallet address to send eth at the end of the auction
  address public primarySaleRecipient;
  /// @dev The adress that receives all primary sales value.
  address public platformFeeRecipient;
  /// @dev The % of primary sales collected by the contract as fees.
  uint128 public platformFeeBps;
  /// @dev the current auction mapping auctionId => Auction
  mapping(bytes32 => Auction) public auctionList;
  ITokenERC721 nft;

  event Kairos_PlacedBid(BidRequest _bidRequest);
  event Kairos_RefundedBid(BidRequest _bidRequest);
  event Kairos_PlacedFiatBid(BidRequest _bidRequest);
  event Kairos_RefundedFiatBid(BidRequest _bidRequest);
  event Kairos_AuctionCreated(bytes32 _auctionId);
  event Kairos_AuctionEnded(bytes32 _auctionId, uint256 _tokenId, address winnindAccount);
  
  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() initializer {}

  function initialize(address _defaultAdmin, 
                      address _primarySaleRecipient,
                      address _nftCollection,
                      uint128 _platformFeeBps,
                      address _platformFeeRecipient) external initializer {
    __EIP712_init("AuctionHouse", "1");

    // Init vars
    _setupRole(DEFAULT_ADMIN_ROLE, _defaultAdmin);
    nft = ITokenERC721(_nftCollection);
    primarySaleRecipient =_primarySaleRecipient;
    platformFeeBps = _platformFeeBps;
    platformFeeRecipient = _platformFeeRecipient;
  }

  //      =====   Setter functions  =====

  /// @dev Lets a module admin set the default recipient of all primary sales.
  function setPrimarySaleRecipient(address _saleRecipient) external onlyRole(DEFAULT_ADMIN_ROLE) {
      primarySaleRecipient = _saleRecipient;
      emit PrimarySaleRecipientUpdated(_saleRecipient);
  }

  /// @dev Lets a module admin update the fees on primary sales.
  function setPlatformFeeInfo(address _platformFeeRecipient, uint256 _platformFeeBps)
      external
      onlyRole(DEFAULT_ADMIN_ROLE)
  {
      if (_platformFeeBps > MAX_BPS) {
        revert MaxBPS(_platformFeeBps, MAX_BPS);
      }

      platformFeeBps = uint64(_platformFeeBps);
      platformFeeRecipient = _platformFeeRecipient;

      emit PlatformFeeInfoUpdated(_platformFeeRecipient, _platformFeeBps);
  }


  ///     =====   Getter functions    =====

  /// @dev Returns the platform fee bps and recipient.
  function getPlatformFeeInfo() external view returns (address, uint16) {
      return (platformFeeRecipient, uint16(platformFeeBps));
  }

  ///     =====   Public functions  =====

  /// @dev Verifies that a bid request is signed by an account holding DEFAULT_ADMIN_ROLE (at the time of the function call).
  function verify(BidRequest calldata _req, bytes calldata _signature) public view returns (bool, address) {
      address signer = recoverAddress(_req, _signature);
      return (hasRole(DEFAULT_ADMIN_ROLE, signer), signer);
  }

  /// @dev place a bid, requires server signature
  function placeBid(BidRequest calldata _req, bytes calldata _signature) external payable 
      AuctionExists(_req.auctionId) 
      BidIsValid(_req.auctionId, _req.amount) returns (address){

    (bool success, address signer) = verify(_req, _signature);
    if (!success) {
      revert InvalidSignature(signer);
    }
    if (msg.sender != _req.account) {
      revert AccountMismatch(msg.sender, _req.account);
    }
    if (msg.value != _req.amount) {
      revert ETHMismatch(msg.value, _req.amount);
    }

    Auction storage auction = auctionList[_req.auctionId];    
    if (auction.winningBid.account != address(0)) {
      if (auction.winningBid.isFiat) {
        emit Kairos_RefundedFiatBid(BidRequest(auction.winningBid.account, 
          _req.auctionId, auction.winningBid.amount));
      } else {
        _refund(_req.auctionId);
      }
    }
    auction.winningBid = Bid(payable(msg.sender), _req.amount, false);
    emit Kairos_PlacedBid(_req);
    return signer;
  }

  ///     =====   Public admin functions  =====

  /// @dev creates an empty auction
  function createAuction(bytes32 auctionId) external 
      onlyRole(DEFAULT_ADMIN_ROLE)
      AuctionDoesntExists(auctionId) {
    Auction memory auction = Auction(auctionId, true, Bid(payable(address(0)), 0x00, false));
    auctionList[auctionId] = auction;
    emit Kairos_AuctionCreated(auctionId);
  }

  /// @dev Refunds the winning bid of the auction
  function placeFiatBid(BidRequest calldata _req) external 
      onlyRole(DEFAULT_ADMIN_ROLE) 
      AuctionExists(_req.auctionId) 
      BidIsValid(_req.auctionId, _req.amount) {
    Auction storage auction = auctionList[_req.auctionId];
    if (auction.winningBid.account != address(0)) {
      if (auction.winningBid.isFiat) {
        emit Kairos_RefundedFiatBid(BidRequest(auction.winningBid.account, 
          _req.auctionId, auction.winningBid.amount));
      } else {
        _refund(_req.auctionId);
      }
    }
    auction.winningBid = Bid(payable(_req.account), _req.amount, true);
    emit Kairos_PlacedFiatBid(_req);
  }

  /// @dev Ends the auction and sends the winning bid to the recipient
  function endAuction(bytes32 auctionId, address winningAccount, string calldata uri) external 
      onlyRole(DEFAULT_ADMIN_ROLE) 
      AuctionExists(auctionId) {
    address account = auctionList[auctionId].winningBid.account;
    uint256 amount = auctionList[auctionId].winningBid.amount;
    bool isFiat = auctionList[auctionId].winningBid.isFiat;
    if (winningAccount != account) {
      revert AccountMismatch(winningAccount, account);
    }
    // Deleting first to prevent re entrancy attacks
    delete auctionList[auctionId];
    if (account != address(0) 
      && amount > 0 
      && !isFiat) {
      uint256 platformFees = (amount * platformFeeBps) / MAX_BPS;
      (bool sent, bytes memory data) = primarySaleRecipient.call{value: amount-platformFees}("");
      if (!sent) {
        revert ETHTransferFail(primarySaleRecipient, amount-platformFees);
      }
      (sent, data) = platformFeeRecipient.call{value: platformFees}("");
      if (!sent) {
        revert ETHTransferFail(platformFeeRecipient, platformFees);
      }
    }
  
    uint256 tokenId;
    if (winningAccount != address(0)) {
      tokenId = nft.mintTo(winningAccount, uri);
    }
    emit Kairos_AuctionEnded(auctionId, tokenId, winningAccount);
  }

  ///     =====   Internal functions  =====
  function _refund(bytes32 auctionId) internal AuctionExists(auctionId) {
    address payable account = auctionList[auctionId].winningBid.account;
    uint256 amount = auctionList[auctionId].winningBid.amount;
    if (account == address(0) || amount <= 0) {
      revert InvalidRefund(account, amount);
    }

    // Deleting first to prevent re entrancy attacks
    delete auctionList[auctionId].winningBid;
    bool callStatus;
    assembly {
      callStatus := call(gas(), account, amount, 0, 0, 0, 0)
    }
    if (!callStatus) {
      revert ETHTransferFail(account, amount);
    }

    emit Kairos_RefundedBid(BidRequest(account, auctionId, amount));
  }


  ///     =====   Private functions =====

  /// @dev Returns the address of the signer of the mint request.
  function recoverAddress(BidRequest calldata _req, bytes calldata _signature) private view returns (address) {
      return _hashTypedDataV4(keccak256(_encodeRequest(_req))).recover(_signature);
  }

  /// @dev Resolves 'stack too deep' error in `recoverAddress`.
  function _encodeRequest(BidRequest calldata _req) private pure returns (bytes memory) {
      return
          abi.encode(
              TYPEHASH,
              _req.account,
              _req.auctionId,
              _req.amount
          );
  }

  ///     =====   Modifiers  =====

  modifier BidIsValid(bytes32 auctionId, uint256 amount) {
    Auction storage auction = auctionList[auctionId];
    if (auction.winningBid.amount > 0) {
      if (amount < auction.winningBid.amount) {
        revert BidBelowThreshold(amount, auction.winningBid.amount);
      } else {
        uint256 increment = amount - auction.winningBid.amount;
        uint256 incrementPercentage = (increment * 100_00) / auction.winningBid.amount;
        if (incrementPercentage < WINNING_BID_THRESHOLD_PERC) {
          revert BidBelowThreshold(amount, auction.winningBid.amount);
        }
      }
    }
    _;
  }

  modifier AuctionExists(bytes32 auctionId) {
    if(!auctionList[auctionId].valid) {
      revert AuctionDoesNotExist(auctionId);
    }
    _;
  }
  modifier AuctionDoesntExists(bytes32 auctionId) {
    if (auctionList[auctionId].valid) {
      revert AuctionAlreadyExist(auctionId);
    }
    _;
  }

}