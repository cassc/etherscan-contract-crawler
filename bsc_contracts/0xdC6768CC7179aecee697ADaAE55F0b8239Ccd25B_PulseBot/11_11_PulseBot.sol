// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Interface to Interact with the Pulse Backend
interface IPulseBackend {
  // Pay rewards from bot earning via this method with reward amount.
  // NOTE: The bot wallet needs to approve reward amount before calling this method
  function payout(uint) external;

  // The bot is able to refill some fund for users to witdraw.
  // NOTE: The bot will need approval like `payout` method
  // and able to get exact amount to be refilled using `refillable` method
  function refill(uint) external;

  // The bot can calls this method instead of `refill` method.
  // This method will charge the bot exact refillable amount automatically.
  function autoRefill() external;

  // The bot reports lost amount using this method.
  function reportLost(uint) external;

  // The bot will be able to return back all user funds using this method when it closed.
  // At that time, the contract will charge the bot current underlying amount
  // NOTE: Don't send any amount to the contract address directly
  function close() external;

  // The bot get exact current amount to need to refilled for user withdrawals using this method.
  function refillable() external view returns (uint);

  // It shows the amount how much the contract deposited to the bot.
  // NOTE: The contract track and update this value each deposits or lost report
  function underlying() external view returns (uint);
}

/**
 * @author @ilikecubes | @i_like_cubes
 * @title Bot Interaction Contract for Pulse
 */
contract PulseBot is AccessControl, Pausable, ReentrancyGuard {
  bytes32 public constant BOT_ROLE = keccak256("BOT_ROLE");
  bytes32 public constant PULSE_ROLE = keccak256("PULSE_ROLE");

  // State Variables
  IPulseBackend internal _pulse;
  IERC20 internal _asset;
  address internal _teamWallet;
  uint256 internal _teamCut;

  // lock for nonReentrant so only a single asset moving TX can occur at a given time
  address internal _lockAddress;

  // Tracks deposit to CEXs
  // NOTE: relies on takeDeposits and refill to function correctly
  mapping(address => uint256) public depositsPerBalance;
  uint256 totalDeposits = 0;

  constructor() {
    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
  }

  // Change the Pulse Backend
  // NOTE: can only be called by the Contract Admin
  function setPulseBackend(
    address address_
  ) external onlyRole(DEFAULT_ADMIN_ROLE) nonReentrant {
    _pulse = IPulseBackend(address_);
  }

  // Change the Asset
  // NOTE: can only be called by the Contract Admin
  function setAsset(address address_) external onlyRole(DEFAULT_ADMIN_ROLE) {
    _asset = IERC20(address_);
  }

  // Change the Team Wallet
  // NOTE: can only be called by the Contract Admin
  function setTeamWallet(
    address address_
  ) external onlyRole(DEFAULT_ADMIN_ROLE) nonReentrant {
    _teamWallet = address_;
  }

  // Change the Team Cut
  // NOTE: can only be called by the Contract Admin | cut_ to be INT percentage
  function setTeamCut(
    uint256 cut_
  ) external onlyRole(DEFAULT_ADMIN_ROLE) nonReentrant {
    _teamCut = cut_;
  }

  // Pause the Contract
  // NOTE: can only be called by the Contract Admin | cut_ to be INT percentage
  function pause() public onlyRole(DEFAULT_ADMIN_ROLE) {
    _pause();
  }

  // Unpause the Contract
  // NOTE: can only be called by the Contract Admin | cut_ to be INT percentage
  function unpause() public onlyRole(DEFAULT_ADMIN_ROLE) {
    _unpause();
  }

  // Get Asset Balance for specific Bot
  // NOTE: can only be called by BOT_ROLE | Bot can use this as true asset balance for profit and loss calculation
  function assetBalanceForAddress()
    public
    view
    onlyRole(BOT_ROLE)
    returns (uint256)
  {
    return depositsPerBalance[msg.sender];
  }

  // Get Asset Balance on Contract
  function assetBalance() public view returns (uint256) {
    return _asset.balanceOf(address(this));
  }

  // PROXY function to get refillable from the Pulse Contract
  function refillable() public view returns (uint256) {
    return _pulse.refillable();
  }

  // PROXY function to refill the Pulse Contract
  // NOTE: Refill is paid from this contracts balance -> the bot must provide asset to this contract first if it doesn't have enough
  function refill(
    uint256 amount_
  ) external whenNotPaused onlyRole(BOT_ROLE) nonReentrant {
    _lockAddress = msg.sender; //lock for nonReentrant
    require(amount_ > 0, "!amount - not enough to refill");
    require(
      amount_ > depositsPerBalance[msg.sender],
      "!balance = BOT doesn't have enough deposited"
    );
    require(
      amount_ > totalDeposits,
      "!balance = Trying to refill more than totalDeposits"
    );
    depositsPerBalance[msg.sender] -= amount_;
    totalDeposits -= amount_;
    _asset.transferFrom(msg.sender, address(this), amount_);
    _asset.approve(address(_pulse), amount_);
    _pulse.refill(amount_);
  }

  // PROXY function to report profit to the Pulse Contract & pays the team share to the team Wallet
  // NOte: Profit is paid from this contracts balance -> the bot must provide the asset to this contract first if it doesn't have enough
  function reportProfit(
    uint256 amount_
  ) external whenNotPaused onlyRole(BOT_ROLE) nonReentrant {
    _lockAddress = msg.sender; //lock for nonReentrant
    uint256 teamShare = (amount_ * _teamCut) / 100;
    uint256 profit = amount_ - teamShare;
    _asset.transferFrom(msg.sender, address(this), amount_);
    _asset.approve(address(_pulse), profit);
    _asset.transfer(_teamWallet, teamShare);
    _pulse.payout(profit);
  }

  // PROXY function to report loss to the Pulse Contract
  function reportLoss(
    uint256 amount_
  ) external whenNotPaused onlyRole(BOT_ROLE) nonReentrant {
    require(
      amount_ > depositsPerBalance[msg.sender],
      "!balance = BOT balance is lower than loss"
    );
    require(
      amount_ > totalDeposits,
      "!balance = totalBalance is lower than loss"
    );
    depositsPerBalance[msg.sender] -= amount_;
    totalDeposits -= amount_;
    _pulse.reportLost(amount_);
  }

  //
  function takeDeposit(
    address exchange_
  ) external whenNotPaused onlyRole(BOT_ROLE) nonReentrant {
    _lockAddress = msg.sender; //lock for nonReentrant
    uint256 change = _pulse.underlying() - totalDeposits;
    depositsPerBalance[msg.sender] += change;
    totalDeposits += change;

    uint256 amount = assetBalance();
    require(amount > 0, "!amount - not moving anything");
    _asset.transfer(exchange_, amount);
  }

  // Admin can rescue all tokens except for asset
  function inCaseTokensGetStuck(
    address _token
  ) external onlyRole(DEFAULT_ADMIN_ROLE) nonReentrant {
    uint256 amount = IERC20(_token).balanceOf(address(this));
    IERC20(_token).transfer(msg.sender, amount);
  }
}