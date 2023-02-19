// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// launchpad Extension Interface
interface IKochiInvest {
  enum EOPCode {
    CREATE,
    BUY,
    CLAIM,
    OWNER_CLAIM,
    SET_REFERRER
  }

  struct SSecurity {
    EOPCode opcode;
    address account;
    uint256 ttl;
  }

  struct SVerify {
    bytes encoded_message;
    bytes32 message_hash;
    bytes signature;
  }

  enum EPresaleType {
    launchpad,
    fairlaunch
  }

  enum EPresaleMetadata {
    total_tokens,
    total_invested,
    total_referrals,
    total_claimed,
    stale,
    finished,
    created_pair
  }

  enum EUserMetadata {
    invested,
    tokens,
    referrals,
    claimed
  }

  struct SPresale {
    uint256 id;
    EPresaleType presale_type;
    address owner;
    address user_token; // Sold token
    address buy_token; // Buyer token
    uint256 soft_cap;
    uint256 hard_cap; // hardcap is not used for fairlaunch presales
    uint256 referral_tokens;
    uint256 total_tokens;
    uint256 lp_tokens; // In the tokens that are sold (user_token)
    uint256 lp_per_mille; // in the tokens the user buys (buy_token)
    uint256 lp_lock_per_mille; // set to 0 for none locked.
    uint256 lp_unlock_ts;
    uint256 total_vested;
    uint256 vested_deadline;
    string dex;
    bool base_currency;
    bool burn_after_sale;
  }

  event SaleCreated(uint256 id);
  event UserBuy(uint256 id, address buyer, uint256 amount, uint256 tokens);
  event UserClaim(uint256 id, address claimer, uint256 amount);
  event OwnerClaim(uint256 id, uint256 amount, uint256 stale, uint256 tax);
  event UserReferral(uint256 id, address referral, address referrer, uint256 amount, bool replaced);

  event PresaleTerminated(uint256 id);
  event PresaleBuyFeeUpdated(uint256 fee);
  event PresaleCreationFeeUpdated(uint256 fee);
  event FeeWalletUpdated(address wallet);
  event FeeTokenUpdated(address token);

  function createLaunchpad(IKochiInvest.SVerify memory verification) external;

  function buy(uint256 amount, IKochiInvest.SVerify memory verification) external payable;

  function claim(IKochiInvest.SVerify memory verification) external;

  function ownerClaim(IKochiInvest.SVerify memory verification) external;

  function ownerCancel(uint256 id) external;

  function setReferrer(IKochiInvest.SVerify memory verification) external;

  function getReferrer(uint256 presale_id, address user) external view returns (address);

  function getUserMetadata(uint256 presale_id, address user)
    external
    view
    returns (
      uint256 invested,
      uint256 tokens,
      uint256 claimed,
      uint256 referrals
    );

  function getPresaleMetadata(uint256 presale_id)
    external
    view
    returns (
      uint256 total_invested,
      uint256 total_tokens,
      uint256 total_referrals,
      uint256 finished // kept as uint256 as stored.
    );

  function getCreationFeeMetadata() external view returns (uint256, address);

  function getCreationFee() external view returns (uint256);

  function getFeeWallet() external view returns (address);

  function getUserInvestment(uint256 presale_id, address user) external view returns (uint256);
}