//██████╗  █████╗ ██╗      █████╗ ██████╗ ██╗███╗   ██╗
//██╔══██╗██╔══██╗██║     ██╔══██╗██╔══██╗██║████╗  ██║
//██████╔╝███████║██║     ███████║██║  ██║██║██╔██╗ ██║
//██╔═══╝ ██╔══██║██║     ██╔══██║██║  ██║██║██║╚██╗██║
//██║     ██║  ██║███████╗██║  ██║██████╔╝██║██║ ╚████║
//╚═╝     ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝ ╚═╝╚═╝  ╚═══╝

pragma solidity 0.8.16;
//SPDX-License-Identifier: BUSL-1.1

import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin/token/ERC20/utils/SafeERC20.sol";
import {BaseRewardPool} from "interfaces/external/aura/AuraBalStaker.sol";
import {CrvDepositorWrapper} from "interfaces/external/aura/AuraDepositor.sol";
import {IRewards} from "interfaces/external/aura/IRewards.sol";
import "./BaseFarmer.sol";

/**
 * @title Warlord auraBAL Farmer contract
 * @author Paladin
 * @notice Contract receiving auraBAL or BAL to farm auraBAL rewards
 */
contract WarAuraBalFarmer is WarBaseFarmer {
  using SafeERC20 for IERC20;

  /**
   * @notice Address of the BAL token
   */
  IERC20 private constant bal = IERC20(0xba100000625a3754423978a60c9317c58a424e3D);
  /**
   * @notice Address of the AURA token
   */
  IERC20 private constant aura = IERC20(0xC0c293ce456fF0ED870ADd98a0828Dd4d2903DBF);
  /**
   * @notice Address of the auraBAL token
   */
  IERC20 private constant auraBal = IERC20(0x616e8BfA43F920657B3497DBf40D6b1A02D4608d);
  /**
   * @notice Address of the auraBAL staking contract
   */
  BaseRewardPool private constant auraBalStaker = BaseRewardPool(0x00A7BA8Ae7bca0B10A32Ea1f8e2a1Da980c6CAd2);
  /**
   * @notice Address of the Aura BAL Depositor contract
   */
  CrvDepositorWrapper private constant balDepositor = CrvDepositorWrapper(0x68655AD9852a99C87C0934c7290BB62CFa5D4123);

  /**
   * @notice Allowed BPS slippage for BAL deposits
   */
  uint256 public slippageBps;

  /**
   * @notice Event emitted when the allowed slippage is updated
   */
  event SetSlippage(uint256 oldSlippage, uint256 newSlippage);

  // Constructor

  constructor(address _controller, address _warStaker) WarBaseFarmer(_controller, _warStaker) {
    // Slippage initial set at 0.5%
    slippageBps = 9950;
  }

  /**
   * @notice Returns the token staked by this contract
   * @return address : address of the token
   */
  function token() external pure returns (address) {
    return address(auraBal);
  }

  /**
   * @notice Sets the slippage allowed for BAL deposits
   * @param _slippageBps Slippage parameter
   */
  function setSlippage(uint256 _slippageBps) external onlyOwner {
    if (_slippageBps > 500) revert Errors.SlippageTooHigh();
    uint256 oldSlippage = slippageBps;
    slippageBps = 10_000 - _slippageBps;

    emit SetSlippage(oldSlippage, slippageBps);
  }

  /**
   * @dev Checks if the token is supported by the Farmer
   * @param _token Address of the token to check
   * @return bool : True if the token is supported
   */
  function _isTokenSupported(address _token) internal pure override returns (bool) {
    return _token == address(bal) || _token == address(auraBal);
  }

  /**
   * @dev Stakes the given token (deposits beforehand if needed)
   * @param _token Address of the token to stake
   * @param _amount Amount to stake
   * @return uint256 : Amount staked
   */
  function _stake(address _token, uint256 _amount) internal override returns (uint256) {
    IERC20(_token).safeTransferFrom(controller, address(this), _amount);

    // Variable used to store the amount of BPT created if token is bal
    uint256 stakableAmount = _amount;

    if (_token == address(bal)) {
      uint256 initialBalance = auraBal.balanceOf(address(this));

      if (bal.allowance(address(this), address(balDepositor)) != 0) bal.safeApprove(address(balDepositor), 0);
      bal.safeIncreaseAllowance(address(balDepositor), _amount);
      uint256 minOut = balDepositor.getMinOut(_amount, slippageBps);
      balDepositor.deposit(_amount, minOut, true, address(0));

      stakableAmount = auraBal.balanceOf(address(this)) - initialBalance;
    }

    _index += stakableAmount;

    if (auraBal.allowance(address(this), address(auraBalStaker)) != 0) auraBal.safeApprove(address(auraBalStaker), 0);
    auraBal.safeIncreaseAllowance(address(auraBalStaker), stakableAmount);
    auraBalStaker.stake(stakableAmount);
    return stakableAmount;
  }

  /**
   * @dev Harvests rewards from the staking contract & sends them to the Controller
   */
  function _harvest() internal override {
    auraBalStaker.getReward(address(this), true);

    bal.safeTransfer(controller, bal.balanceOf(address(this)));
    aura.safeTransfer(controller, aura.balanceOf(address(this)));

    uint256 extraRewardsLength = auraBalStaker.extraRewardsLength();

    for (uint256 i; i < extraRewardsLength;) {
      IRewards rewarder = IRewards(auraBalStaker.extraRewards(i));
      IERC20 _token = IERC20(rewarder.rewardToken());
      uint256 balance = _token.balanceOf(address(this));
      if (balance != 0) {
        _token.safeTransfer(controller, balance);
      }

      unchecked {
        ++i;
      }
    }
  }

  /**
   * @dev Returns the balance of tokens staked by this contract in the staking contract
   * @return uint256 : staked balance for this contract
   */
  function _stakedBalance() internal view override returns (uint256) {
    return auraBalStaker.balanceOf(address(this));
  }

  /**
   * @dev Withdraws tokens and sends them to the receiver
   * @param receiver Address to receive the tokens
   * @param amount Amount to send
   */
  function _sendTokens(address receiver, uint256 amount) internal override {
    auraBalStaker.withdraw(amount, false);
    auraBal.safeTransfer(receiver, amount);
  }

  /**
   * @dev Withdraws & migrates the tokens hold by this contract to another address
   * @param receiver Address to receive the migrated tokens
   */
  function _migrate(address receiver) internal override {
    // Unstake and send auraBal
    uint256 auraBalStakedBalance = auraBalStaker.balanceOf(address(this));
    auraBalStaker.withdraw(auraBalStakedBalance, false);
    auraBal.safeTransfer(receiver, auraBalStakedBalance);
  }

  /**
   * @notice Recover ERC2O tokens in the contract
   * @dev Recover ERC2O tokens in the contract
   * @param _token Address of the ERC2O token
   * @return bool: success
   */
  function recoverERC20(address _token) external onlyOwner returns (bool) {
    if (_token == address(0)) revert Errors.ZeroAddress();
    uint256 amount = IERC20(_token).balanceOf(address(this));
    if (amount == 0) revert Errors.ZeroValue();

    IERC20(_token).safeTransfer(owner(), amount);

    return true;
  }
}