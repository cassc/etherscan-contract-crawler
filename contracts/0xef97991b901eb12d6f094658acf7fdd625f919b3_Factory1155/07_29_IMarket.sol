// SPDX-License-Identifier: None
pragma solidity =0.8.13;

interface IMarket {
  event Listed(uint256 indexed lockId, address indexed lender, Lend lend);
  event Rented(uint256 indexed rentId, address indexed renter, uint256 lockId, Rent rent);
  event Canceled(uint256 indexed lockId);
  event WhiteListed(address indexed collection, address indexed vault);
  event Withdrawn(uint256 indexed lockId);
  event Claimed(uint256 indexed lockId);
  event ClaimedRoyalty(address indexed collection);

  enum LockIdTarget {
    Lender,
    Renter,
    Vault,
    Token
  }

  enum PaymentMethod {
    // 32bit
    OneTime,
    Loan,
    BNPL,
    Subscription
  }

  /*
   * Market only returns data for listings
   * Original NFT is in the Vault contract
   */
  struct Lend {
    uint64 minRentalDuration; // days
    uint64 maxRentalDuration; // days
    uint64 lockStartTime;
    uint64 lockExpireTime;
    uint256 dailyRentalPrice; // wei
    uint256 tokenId;
    uint256 amount; // for ERC1155
    address vault; //160 bit
    address paymentToken; // 160 bit
    address lender; // 160 bit
    address privateAddress;
    PaymentMethod paymentMethod; // 32bit
  }

  struct Rent {
    address renterAddress;
    uint256 rentId;
    uint256 rentalStartTime;
    uint256 rentalExpireTime;
    uint256 amount;
  }

  struct LendRent {
    Lend lend;
    Rent[] rent;
  }

  function getLendRent(uint256 _lockId) external view returns (LendRent memory);

  function paymentTokenWhiteList(address _paymentToken) external view returns (uint256);

  function protocolAdminFeeRatio() external view returns (uint256);
}

interface IMarketOwner {
  function owner() external view returns (address);
}