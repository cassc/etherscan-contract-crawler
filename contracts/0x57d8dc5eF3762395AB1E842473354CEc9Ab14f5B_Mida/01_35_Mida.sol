// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

//  __  __ _____ _____
// |  \/  |_   _|  __ \   /\
// | \  / | | | | |  | | /  \
// | |\/| | | | | |  | |/ /\ \
// | |  | |_| |_| |__| / ____ \
// |_|  |_|_____|_____/_/    \_\
//
// Mida Token
// t.me/midatoken
// by: @korkey128k
//

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./Mida/Mineable.sol";

import "./MTM.sol";

contract Mida is ERC20, ReentrancyGuard, Mineable {

  // Mida Token Miner NFT
  MTM private immutable _mtm;
  address public mtm;

  address public constant BA_ADDRESS =
    address(0xd2dc058f4068ec0e42655F8a385Eb6333FB67ab6);

  uint128 internal constant RESOLUTION = 1e6;

  uint128 private constant TOTAL_SUPPLY =
    42_000_000_000_000 * RESOLUTION; // forty-two trillion

  uint128 private constant BA_ALLOCATION =
    TOTAL_SUPPLY / 2; // half of supply for liquidity

  uint128 private constant TOTAL_MINEABLE_SUPPLY =
    TOTAL_SUPPLY - BA_ALLOCATION; // twenty-one trillion

  uint128 private constant MSHARE_RATE =
    694_200; // 1 MShare == six hundred ninety four thousand, two hundred

  uint128 public pendingMidaMined;
  uint128 public totalMidaMined;

  event EnterMine(OwnerMiner ownerMiner);
  event RewardsClaim(address ownerAddress, uint rewardsAndPeriod);
  event MinerRetrieval(address ownerAddress, uint[] minerIds);

  error InvalidMTMOwner();
  error NotEnoughMSharesToMine();
  error ReloadPeriodNotStarted();
  error CannotEnterMineDuringMiningPeriod(uint timeToChangeStatus);
  error CannotEnterMineWithPendingRewards(uint rewards);
  error CannotRetreiveMtmsDuringMiningPeriod(uint timeToChangeStatus);
  error TotalSupplyHasBeenReached(uint maxSupply);
  error NoRewardsToClaim(address claimer);
  error NoMinersToRetrieve(address retriever);
  error OwnerIsMining(uint periodId);

  modifier notMining() {
    if(ownerMiner[_msgSender()].periodId == currentPeriod.periodId) {
      revert OwnerIsMining(currentPeriod.periodId);
    }

    _;
  }

  modifier minerStartable() {
    _;

    if(shouldStartMiner()) {
      minerStart();
    }
  }

  modifier minerEndable() {
    if(shouldEndMiner()) {
      minerEnd();
    }

    _;
  }

  modifier onlyReload() {
    if(currentPeriod.status != PeriodStatus.Reload) {
      revert CannotEnterMineDuringMiningPeriod(currentPeriod.timeToChangeStatus);
    }

    _;
  }

  modifier maxSupplyNotReached() {
    if(pendingMidaMined + totalSupply() == maxSupply()) {
      revert TotalSupplyHasBeenReached(maxSupply());
    }

    _;
  }

  constructor(uint64 _launchTime) ERC20("Mida", "MIDA") Mineable(_launchTime) {
    _mint(BA_ADDRESS, BA_ALLOCATION);

    mtm = address(new MTM());
    _mtm = MTM(mtm);
  }

  function maxSupply() public pure returns(uint128) {
    return TOTAL_SUPPLY;
  }

  function mineableSupply() public pure returns(uint128) {
    return TOTAL_MINEABLE_SUPPLY;
  }

  function mShareRate() public pure returns(uint128) {
    return MSHARE_RATE;
  }

  function decimals() public pure override returns(uint8) {
    return 6;
  }

  // @dev Public function for enterMine
  function enterMine(
    uint[] calldata mtmIds
  ) external
    nonReentrant
    maxSupplyNotReached
    notMining
    onlyReload
    minerStartable {
    _enterMine(mtmIds);
  }

  // @dev Public function to claim rewards && enterMine
  // Gas saving function to extract rewards and keep on mining
  function continueMining()
    external
    nonReentrant
    minerEndable
    maxSupplyNotReached
    notMining
    onlyReload
    minerStartable {
    _claimRewards();
    _reEnterMine();
  }

  // @dev Return all rewards and MTMs to miner & exit the mine
  function exitMine()
    external
    minerEndable
    notMining
    minerStartable {
    _claimRewards();
    _retreiveMtms();
  }

  // @dev Enter the 30 day mine
  // @param mtmIds array of MTM ids to enter the mine with
  function _enterMine(uint[] memory mtmIds) internal {
    OwnerMiner storage _ownerMiner = ownerMiner[_msgSender()];

    uint128 totalMPoints;

    for(uint i; i < mtmIds.length;) {
      uint mtmId = mtmIds[i];

      // If this mtm isn't owned by msgSender, revert out
      if(_mtm.ownerOf(mtmId) != _msgSender()) {
        revert InvalidMTMOwner();
      }

      (, uint128 mPoints, ) = _mtm.mtmStorage(mtmId);

      totalMPoints += uint128(mPoints);

      _mtm.enterMine(mtmId);

      _ownerMiner.mtmIds.push(mtmId);

      unchecked {
        i++;
      }
    }

    uint128 midaMining = _verifyRewards(totalMPoints * MSHARE_RATE);

    _ownerMiner.rewards += midaMining;
    _ownerMiner.periodId = currentPeriod.periodId;

    emit EnterMine(_ownerMiner);

  }

  // @dev It's assumed here that miners HAVE NOT been claimed.
  //      If they have, this fails with InvalidMTMOwner
  function _reEnterMine() internal {
    OwnerMiner storage _ownerMiner = ownerMiner[_msgSender()];

    uint[] memory mtmIds = _ownerMiner.mtmIds;

    uint128 totalMPoints;

    for(uint i; i < mtmIds.length;) {
      uint mtmId = mtmIds[i];

      // The inverse from _enterMine. Verify this mtm is burned using _mtm.burntOwners
      if(_mtm.burntOwners(mtmId) != _msgSender()) {
        revert InvalidMTMOwner();
      }

      (, uint128 mPoints, ) = _mtm.mtmStorage(mtmId);

      totalMPoints += uint128(mPoints);

      unchecked {
        i++;
      }
    }

    uint128 midaMining = _verifyRewards(totalMPoints * MSHARE_RATE);

    _ownerMiner.rewards += midaMining;
    _ownerMiner.periodId = currentPeriod.periodId;

    emit EnterMine(_ownerMiner);

    if(shouldStartMiner()) {
      minerStart();
    }
  }

  function _claimRewards() internal {
    OwnerMiner storage _ownerMiner = ownerMiner[_msgSender()];
    uint128 rewards = _ownerMiner.rewards;
    uint56 periodId = _ownerMiner.periodId;

    if(rewards == 0) {
      revert NoRewardsToClaim(_msgSender());
    }

    _ownerMiner.rewards = uint128(0);
    _ownerMiner.periodId = uint56(0);

    _mint(_msgSender(), rewards);
    pendingMidaMined -= rewards;

    emit RewardsClaim(_msgSender(), uint(rewards) | uint(periodId) << 128);
  }

  // @dev Claim MTMs
  // @notice Only MTMs that aren't mining are claimable
  function _retreiveMtms() internal {
    OwnerMiner storage _ownerMiner = ownerMiner[_msgSender()];

    uint[] memory miners = _ownerMiner.mtmIds;

    if(miners.length == 0) {
      revert NoMinersToRetrieve(_msgSender());
    }

    for(uint i; i < miners.length;) {

      _mtm.exitMine(miners[i]);

      unchecked {
        i++;
      }
    }

    delete _ownerMiner.mtmIds;

    emit MinerRetrieval(_msgSender(), miners);
  }

  //TODO maybe come back to this
  function _verifyRewards(uint128 midaMining) internal returns(uint128) {
    if(midaMining == 0) {
      revert NotEnoughMSharesToMine();
    }

    // Do these MIDA push us over totalSupply?
    uint128 supplyAfterMining = pendingMidaMined + midaMining;

    if(supplyAfterMining + totalSupply() > maxSupply()) {
      // Reduce this midaMining so we hit maxSupply()
      midaMining -= uint128(supplyAfterMining + totalSupply() - maxSupply());
    }

    totalMidaMined += midaMining;
    currentPeriod.totalMidaMined += midaMining;
    pendingMidaMined += midaMining;

    return midaMining;
  }

}