// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.9;

// import "hardhat/console.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';

import "./interfaces/IRewardBooster.sol";
import "../lib/CurrencyTransferLib.sol";

contract esLSD is Ownable, ReentrancyGuard, ERC20("esLSD Token", "esLSD") {
  using Address for address;
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  address public rewardBooster;
  IERC20 public immutable lsdToken;

  IUniswapV2Router02 public uniswapV2Router;
  IUniswapV2Pair public lsdEthPair;

  uint256 public vestingPeriod = 90 days;

  mapping(address => VestingInfo) public userVestings; // User's vesting instances

  struct VestingInfo {
    uint256 amount;
    uint256 startTime;
    uint256 endTime;
  }

  constructor(address _lsdToken, address _uniswapV2Router, address _lsdEthPair) Ownable() {
    require(_lsdToken != address(0), "Zero address detected");
    require(_uniswapV2Router != address(0), "Zero address detected");
    require(_lsdEthPair != address(0), "Zero address detected");

    lsdToken = IERC20(_lsdToken);
    uniswapV2Router = IUniswapV2Router02(_uniswapV2Router);
    lsdEthPair = IUniswapV2Pair(_lsdEthPair);
  }

  receive() external payable virtual {}

  /*******************************************************/
  /****************** MUTATIVE FUNCTIONS *****************/
  /*******************************************************/

  /**
   * @dev Escrow $LSD tokens to get $esLSD tokens
   * @param amount Amount of $LSD to escrow
   */
  function escrow(uint256 amount) external nonReentrant {
    require(amount > 0, "Amount must be greater than 0");

    lsdToken.safeTransferFrom(_msgSender(), address(this), amount);
    _mint(_msgSender(), amount);

    emit Escrow(_msgSender(), amount);
  }

  /**
   * @dev Withdraw unlocked $LSD tokens if there are ongoing redeems
   */
  function claim() external nonReentrant {
    VestingInfo storage vestingInfo = userVestings[_msgSender()];
    require(vestingInfo.amount > 0, "No tokens to claim");
    require(block.timestamp >= vestingInfo.startTime, "Vesting not started");

    uint256 unlocked = 0;
    if (block.timestamp >= vestingInfo.endTime) {
      unlocked = vestingInfo.amount;
      delete userVestings[_msgSender()];
    }
    else {
      unlocked = vestingInfo.amount.mul(block.timestamp.sub(vestingInfo.startTime)).div(vestingInfo.endTime.sub(vestingInfo.startTime));
      vestingInfo.amount = vestingInfo.amount.sub(unlocked);
      vestingInfo.startTime = block.timestamp;
    }

    if (unlocked > 0) {
      lsdToken.safeTransfer(_msgSender(), unlocked);
      _burn(address(this), unlocked);
      emit Claim(_msgSender(), unlocked);
    }
  }

  /**
   * @dev Vest $LSD tokens from $esLSD tokens
   * @param amount Amount of $esLSD to vest
   */ 
  function vest(uint256 amount) external nonReentrant {
    require(amount > 0, "Amount must be greater than 0");
    require(amount <= balanceOf(_msgSender()), "Vest amount exceeds balance");

    _transfer(_msgSender(), address(this), amount);

    VestingInfo storage vestingInfo = userVestings[msg.sender];
    uint256 accruedAmount = amount;
    uint256 unlocked = 0;
    // Case 1: No ongoing vesting
    if (vestingInfo.amount == 0) {

    }
    // Case 2: Ongoing vesting
    else {
      require(block.timestamp >= vestingInfo.startTime, "Vesting not started");
      // Case 2.1: Ongoing vesting, all vested
      if (block.timestamp >= vestingInfo.endTime) {
        unlocked = vestingInfo.amount;
      }
      // Case 2.2: Ongoing vesting, partial vested
      else {
        unlocked = vestingInfo.amount.mul(block.timestamp.sub(vestingInfo.startTime)).div(vestingInfo.endTime.sub(vestingInfo.startTime));
        accruedAmount = accruedAmount.add(vestingInfo.amount).sub(unlocked);
      }
    }

    if (unlocked > 0) {
      lsdToken.safeTransfer(_msgSender(), unlocked);
      _burn(address(this), unlocked);
      emit Claim(_msgSender(), unlocked);
    }

    vestingInfo.amount = accruedAmount;
    vestingInfo.startTime = block.timestamp;
    vestingInfo.endTime = block.timestamp.add(vestingPeriod);
    emit Vest(_msgSender(), amount, vestingInfo.amount, vestingPeriod);
  }

  function zapVest() external payable nonReentrant {
    require(msg.value > 0, "Zero paired ETH amount");
    require(rewardBooster != address(0), "Reward booster not set");
    IRewardBooster(rewardBooster).assertStakeCount(_msgSender());

    VestingInfo storage vestingInfo = userVestings[_msgSender()];
    require(vestingInfo.amount > 0, "No tokens to claim");
    require(block.timestamp >= vestingInfo.startTime, "Vesting not started");

    uint256 unlocked = 0;
    uint256 zapAmount = 0;
    if (block.timestamp >= vestingInfo.endTime) {
      unlocked = vestingInfo.amount;
    }
    else {
      unlocked = vestingInfo.amount.mul(block.timestamp.sub(vestingInfo.startTime)).div(vestingInfo.endTime.sub(vestingInfo.startTime));
      zapAmount = vestingInfo.amount.sub(unlocked);
    }
    require(zapAmount > 0, "No unlocked tokens to zap vest");

    if (unlocked > 0) {
      lsdToken.safeTransfer(_msgSender(), unlocked);
      _burn(address(this), unlocked);
      emit Claim(_msgSender(), unlocked);
    }

    _burn(address(this), zapAmount);
    lsdToken.approve(address(uniswapV2Router), zapAmount);
    (uint256 amountLSD, uint256 amountETH, uint256 amountLP) = uniswapV2Router.addLiquidityETH{value: msg.value}(address(lsdToken), zapAmount, zapAmount, 0, address(this), block.timestamp);
    require(amountLSD == zapAmount, "Incorrect amount of LSD tokens");
    if (msg.value > amountETH) {
      CurrencyTransferLib.transferCurrency(CurrencyTransferLib.NATIVE_TOKEN, address(this), _msgSender(), msg.value.sub(amountETH));
    }

    lsdEthPair.approve(rewardBooster, amountLP);
    IRewardBooster(rewardBooster).delegateZapStake(_msgSender(), amountLP);
    emit ZapVest(_msgSender(), zapAmount);

    delete userVestings[_msgSender()];
  }


  /********************************************/
  /*********** RESTRICTED FUNCTIONS ***********/
  /********************************************/
  function setRewardBooster(address _rewardBooster) external onlyOwner {
    require(_rewardBooster != address(0), "Zero address detected");
    rewardBooster = _rewardBooster;
  }


  /**************************************************/
  /****************** PUBLIC VIEWS ******************/
  /**************************************************/

  /**
   * @dev Query the amount of $LSD tokens that can be redeemed
   * @param account Account to query
   */
  function claimableAmount(address account) public view returns (uint256) {
    require(account != address(0), "Zero address detected");

    VestingInfo memory vestingInfo = userVestings[account];
    if (vestingInfo.amount == 0) {
      return 0;
    }

    require(block.timestamp >= vestingInfo.startTime, "Vesting not started");
    if (block.timestamp >= vestingInfo.endTime) {
      return vestingInfo.amount;
    }
    else {
      return vestingInfo.amount.mul(block.timestamp.sub(vestingInfo.startTime)).div(vestingInfo.endTime.sub(vestingInfo.startTime));
    }
  }

  /********************************************/
  /****************** EVENTS ******************/
  /********************************************/

  event Escrow(address indexed userAddress, uint256 amount);
  event Claim(address indexed userAddress, uint256 amount);
  event Vest(address indexed userAddress, uint256 amount, uint256 accruedAmount, uint256 period);
  event ZapVest(address indexed userAddress, uint256 amount);
}