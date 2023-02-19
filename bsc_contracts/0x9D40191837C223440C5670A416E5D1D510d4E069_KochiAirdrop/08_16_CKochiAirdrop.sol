// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// openzeppelin contracts
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

// Uniswap V2
import "../interfaces/IUniswapV2Pair.sol";
import "../interfaces/IUniswapV2Router.sol";
import "../interfaces/IUniswapV2Factory.sol";

// interface and library
import "../interfaces/IKochiLock.sol";
import "../interfaces/IKochiVest.sol";
import "../interfaces/IKochiAirdrop.sol";
import "../libraries/LTransfers.sol";

// hardhat tools
// DEV ENVIRONMENT ONLY
import "hardhat/console.sol";

// this contract allows to lock liquidity cheaply and on multiple DEXs
contract KochiAirdrop is ContextUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable, OwnableUpgradeable, IKochiAirdrop {
  // constants
  address private constant DEAD = 0x0000000000000000000000000000000000000000;

  SAirdropMetadata[] public airdrops;
  IKochiLock public kochiLock;
  IKochiVest public kochiVest;

  // upgradable gap
  uint256[50] private _gap;

  function initialize(address _kochiLock, address _kochiVest) public initializer {
    __Context_init();
    __Pausable_init();
    __ReentrancyGuard_init();
    __Ownable_init();

    kochiLock = IKochiLock(_kochiLock);
    kochiVest = IKochiVest(_kochiVest);
  }

  //////////////////////////////////////////////////////////////////////////////
  // Airdrop Creation
  //////////////////////////////////////////////////////////////////////////////

  function airdrop(
    address _token,
    address[] memory _recipients,
    uint256[] memory _amounts,
    ESchedule _schedule,
    uint256 _startline,
    uint256 _deadline,
    uint256 _schedule_duration
  ) external override nonReentrant whenNotPaused {
    // check if the airdrop is valid
    require(_recipients.length == _amounts.length, "KochiAirdrop: number of recipients and amounts do not match");
    require(_recipients.length > 0, "KochiAirdrop: number of recipients cannot be 0");
    require(_schedule == ESchedule.instant || _schedule_duration > 0, "KochiAirdrop: ESchedule duration must be greater than 0, or be set to instant");

    // if deadline is 0, then the airdrop will never expire, therefore won't be able to be claimed back by the owner.
    require(_deadline == 0 || _deadline > _startline, "KochiAirdrop: deadline must be greater than startline, or be set to 0 to never expire");
    require(_deadline == 0 || _deadline > block.timestamp, "KochiAirdrop: deadline must be greater than current time, or be set to 0 to never expire");

    // create the airdrop
    airdrops.push(
      SAirdropMetadata({
        uid: airdrops.length,
        creator: _msgSender(),
        created_at: block.timestamp,
        token: _token,
        recipients: _recipients,
        amounts: _amounts,
        schedule: _schedule,
        startline: _startline,
        deadline: _deadline,
        schedule_duration: _schedule_duration,
        owner_claimed: false
      })
    );

    uint256 sum = 0;
    for (uint256 i = 0; i < _amounts.length; i++) {
      sum += _amounts[i];
    }

    // transfer the tokens to the contract
    LTransfers.internalTransferFrom(_msgSender(), address(this), sum, IERC20(_token));

    // emit the event
    emit Airdropped(airdrops[airdrops.length - 1]);
  }

  function airdropETH(
    address[] memory _recipients,
    uint256[] memory _amounts,
    ESchedule _schedule,
    uint256 _startline,
    uint256 _deadline,
    uint256 _schedule_duration
  ) external payable override nonReentrant whenNotPaused {
    // check if the airdrop is valid
    require(_recipients.length == _amounts.length, "KochiAirdrop: number of recipients and amounts do not match");
    require(_recipients.length > 0, "KochiAirdrop: number of recipients cannot be 0");
    require(_schedule == ESchedule.instant || _schedule_duration > 0, "KochiAirdrop: ESchedule duration must be greater than 0, or be set to instant");

    // if deadline is 0, then the airdrop will never expire, therefore won't be able to be claimed back by the owner.
    require(_deadline == 0 || _deadline > _startline, "KochiAirdrop: deadline must be greater than startline, or be set to 0 to never expire");
    require(_deadline == 0 || _deadline > block.timestamp, "KochiAirdrop: deadline must be greater than current time, or be set to 0 to never expire");

    uint256 sum = 0;
    unchecked {
      for (uint256 i = 0; i < _amounts.length; i++) {
        sum += _amounts[i];
      }
    }

    // check if the amount sent is enough
    require(msg.value == sum, "KochiAirdrop: the amount sent does not match the sum of the amounts");

    // create the airdrop
    airdrops.push(
      SAirdropMetadata({
        uid: airdrops.length,
        creator: _msgSender(),
        created_at: block.timestamp,
        token: DEAD,
        recipients: _recipients,
        amounts: _amounts,
        schedule: _schedule,
        startline: _startline,
        deadline: _deadline,
        schedule_duration: _schedule_duration,
        owner_claimed: false
      })
    );

    // emit the event
    emit Airdropped(airdrops[airdrops.length - 1]);
  }

  //////////////////////////////////////////////////////////////////////////////
  // Claiming
  //////////////////////////////////////////////////////////////////////////////

  function claim(uint256 uid) external override nonReentrant {
    // check if the airdrop is valid
    require(uid < airdrops.length, "KochiAirdrop: airdrop does not exist");
    SAirdropMetadata memory _airdrop = airdrops[uid];

    require(_airdrop.owner_claimed == false, "KochiAirdrop: airdrop has been marked as stale and claimed by the owner");

    // check if the airdrop is valid
    require(_airdrop.recipients.length > 0, "KochiAirdrop: airdrop has already been fully claimed");
    require(_airdrop.deadline == 0 || _airdrop.deadline >= block.timestamp, "KochiAirdrop: airdrop has expired");
    require(_airdrop.startline <= block.timestamp, "KochiAirdrop: airdrop has not started yet");

    // check if the user is eligible
    uint256 amount = 0;
    for (uint256 i = 0; i < _airdrop.recipients.length; i++) {
      if (_airdrop.recipients[i] == _msgSender()) {
        amount += _airdrop.amounts[i];
        airdrops[uid].amounts[i] = 0;
      }
    }
    require(amount > 0, "KochiAirdrop: user is not eligible");

    address schedule_contract = address(this);
    if (_airdrop.schedule == ESchedule.instant) {
      // transfer the tokens to the user
      if (_airdrop.token == DEAD) {
        LTransfers.internalTransferToETH(_msgSender(), amount);
      } else {
        LTransfers.internalTransferTo(_msgSender(), amount, IERC20(_airdrop.token));
      }
    } else if (_airdrop.schedule == ESchedule.locked) {
      // create the lock
      schedule_contract = address(kochiLock);
      if (_airdrop.token == DEAD) {
        kochiLock.lockETH{value: amount}(_msgSender(), block.timestamp + _airdrop.schedule_duration);
      } else {
        IERC20(_airdrop.token).approve(address(kochiLock), amount);
        kochiLock.lock(_airdrop.token, amount, _msgSender(), block.timestamp + _airdrop.schedule_duration);
      }
    } else if (_airdrop.schedule == ESchedule.vested) {
      // create the vest
      schedule_contract = address(kochiVest);
      if (_airdrop.token == DEAD) {
        kochiVest.vestETH{value: amount}(IKochiVest.EVestType.linear, _msgSender(), block.timestamp, block.timestamp + _airdrop.schedule_duration);
      } else {
        IERC20(_airdrop.token).approve(address(kochiVest), amount);
        kochiVest.vest(IKochiVest.EVestType.linear, _msgSender(), _airdrop.token, amount, block.timestamp, block.timestamp + _airdrop.schedule_duration);
      }
    } else revert("KochiAirdrop: invalid schedule");

    emit Claimed(uid, _airdrop.token, _msgSender(), amount, _airdrop.schedule, _airdrop.startline, _airdrop.deadline, _airdrop.schedule_duration, schedule_contract);
  }

  function ownerClaimStale(uint256 uid) external override nonReentrant whenNotPaused {
    // check if the airdrop is valid
    require(uid < airdrops.length, "KochiAirdrop: airdrop does not exist");
    SAirdropMetadata memory _airdrop = airdrops[uid];

    // check if the airdrop is valid and can be claimed
    require(_airdrop.recipients.length > 0, "KochiAirdrop: airdrop has already been fully claimed");
    require(_airdrop.deadline > 0 && _airdrop.deadline < block.timestamp, "KochiAirdrop: airdrop has not expired");
    require(_airdrop.owner_claimed == false, "KochiAirdrop: airdrop has already been claimed by the owner");
    require(_airdrop.creator == _msgSender(), "KochiAirdrop: only the creator can claim the airdrop");

    // mark the airdrop as owner_claimed
    airdrops[uid].owner_claimed = true;

    // check if the user is eligible
    uint256 amount = 0;
    for (uint256 i = 0; i < _airdrop.recipients.length; i++) {
      amount += _airdrop.amounts[i];
    }
    require(amount > 0, "KochiAirdrop: airdrop has already been fully claimed, nothing is left to claim");

    // transfer the tokens to the user
    if (_airdrop.token == DEAD) {
      LTransfers.internalTransferToETH(_airdrop.creator, amount);
    } else {
      LTransfers.internalTransferTo(_airdrop.creator, amount, IERC20(_airdrop.token));
    }

    emit OwnerClaimed(uid, _airdrop.token, _airdrop.creator, amount);
  }

  //////////////////////////////////////////////////////////////////////////////
  // Getters
  //////////////////////////////////////////////////////////////////////////////

  // get all airdrops created by the user
  function getMyAirdrops() external view override returns (uint256[] memory uids) {
    uids;

    uint256 count = 0;
    for (uint256 i = 0; i < airdrops.length; i++) {
      if (airdrops[i].creator == _msgSender()) {
        uids[count] = i;
        count++;
      }
    }

    return uids;
  }

  // get the aidrop where the user has remaining tokens to claim as recipient
  function getClaimable(address beneficiary, uint256 uid) external view override returns (uint256 amount) {
    require(uid < airdrops.length, "KochiAirdrop: airdrop does not exist");
    SAirdropMetadata memory _airdrop = airdrops[uid];

    // loop through all the recipients and find the ones that match the beneficiary
    for (uint256 i = 0; i < _airdrop.recipients.length; i++) {
      if (_airdrop.recipients[i] == beneficiary && _airdrop.startline <= block.timestamp && (_airdrop.deadline == 0 || _airdrop.deadline >= block.timestamp)) {
        amount += _airdrop.amounts[i];
      }
    }

    return amount;
  }

  function getAirdropMetadata(uint256 uid) external view override returns (SAirdropMetadata memory metadata) {
    require(uid < airdrops.length, "KochiAirdrop: airdrop does not exist");
    return airdrops[uid];
  }

  //////////////////////////////////////////////////////////////////////////////
  // Kochi Support
  //////////////////////////////////////////////////////////////////////////////

  function setPaused(bool _paused) external onlyOwner {
    if (_paused) _pause();
    else _unpause();
  }

  function setKochiLock(address _kochiLock) external onlyOwner {
    kochiLock = IKochiLock(_kochiLock);
  }

  function setKochiVest(address _kochiVest) external onlyOwner {
    kochiVest = IKochiVest(_kochiVest);
  }
}