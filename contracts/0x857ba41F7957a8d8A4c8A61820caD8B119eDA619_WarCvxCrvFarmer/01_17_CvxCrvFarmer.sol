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
import {CvxCrvStaking} from "interfaces/external/convex/CvxCrvStaking.sol";
import {CrvDepositor} from "interfaces/external/convex/CrvDepositor.sol";
import "./BaseFarmer.sol";

/**
 * @title Warlord cvxCRV Farmer contract
 * @author Paladin
 * @notice Contract receiving cvxCRV or CRV to farm cvxCRV rewards
 */
contract WarCvxCrvFarmer is WarBaseFarmer {
  using SafeERC20 for IERC20;

  /**
   * @notice Address of the CRV token
   */
  IERC20 private constant crv = IERC20(0xD533a949740bb3306d119CC777fa900bA034cd52);
  /**
   * @notice Address of the cvxCRV token
   */
  IERC20 private constant cvxCrv = IERC20(0x62B9c7356A2Dc64a1969e19C23e4f579F9810Aa7);
  /**
   * @notice Address of the cvxCRV staking contract
   */
  CvxCrvStaking private constant cvxCrvStaker = CvxCrvStaking(0xaa0C3f5F7DFD688C6E646F66CD2a6B66ACdbE434);
  /**
   * @notice Address of the Convex CRV depositor contract
   */
  CrvDepositor private constant crvDepositor = CrvDepositor(0x8014595F2AB54cD7c604B00E9fb932176fDc86Ae);

  // Constructor

  constructor(address _controller, address _warStaker) WarBaseFarmer(_controller, _warStaker) {}

  /**
   * @notice Returns the token staked by this contract
   * @return address : address of the token
   */
  function token() external pure returns (address) {
    return address(cvxCrv);
  }

  /**
   * @notice Sets the reward weight for the cvxCRV staking contract
   * @param weight Weight parameter
   */
  function setRewardWeight(uint256 weight) external onlyOwner whenNotPaused {
    cvxCrvStaker.setRewardWeight(weight);
  }

  /**
   * @dev Checks if the token is supported by the Farmer
   * @param _token Address of the token to check
   * @return bool : True if the token is supported
   */
  function _isTokenSupported(address _token) internal pure override returns (bool) {
    return _token == address(crv) || _token == address(cvxCrv);
  }

  /**
   * @dev Stakes the given token (deposits beforehand if needed)
   * @param _token Address of the token to stake
   * @param _amount Amount to stake
   * @return uint256 : Amount staked
   */
  function _stake(address _token, uint256 _amount) internal override returns (uint256) {
    IERC20(_token).safeTransferFrom(controller, address(this), _amount);

    uint256 stakableAmount = _amount;

    if (_token == address(crv)) {
      uint256 initialBalance = cvxCrv.balanceOf(address(this));
      if (crv.allowance(address(this), address(crvDepositor)) != 0) crv.safeApprove(address(crvDepositor), 0);
      crv.safeIncreaseAllowance(address(crvDepositor), _amount);
      crvDepositor.deposit(_amount, true, address(0));

      stakableAmount = cvxCrv.balanceOf(address(this)) - initialBalance;
    }

    _index += stakableAmount;

    if (cvxCrv.allowance(address(this), address(cvxCrvStaker)) != 0) cvxCrv.safeApprove(address(cvxCrvStaker), 0);
    cvxCrv.safeIncreaseAllowance(address(cvxCrvStaker), stakableAmount);
    cvxCrvStaker.stake(stakableAmount, address(this));
    return stakableAmount;
  }

  /**
   * @dev Harvests rewards from the staking contract & sends them to the Controller
   */
  function _harvest() internal override {
    cvxCrvStaker.getReward(address(this), controller);
  }

  /**
   * @dev Returns the balance of tokens staked by this contract in the staking contract
   * @return uint256 : staked balance for this contract
   */
  function _stakedBalance() internal view override returns (uint256) {
    return cvxCrvStaker.balanceOf(address(this));
  }

  /**
   * @dev Withdraws tokens and sends them to the receiver
   * @param receiver Address to receive the tokens
   * @param amount Amount to send
   */
  function _sendTokens(address receiver, uint256 amount) internal override {
    cvxCrvStaker.withdraw(amount);
    cvxCrv.safeTransfer(receiver, amount);
  }

  /**
   * @dev Withdraws & migrates the tokens hold by this contract to another address
   * @param receiver Address to receive the migrated tokens
   */
  function _migrate(address receiver) internal override {
    // Unstake and send cvxCrv
    uint256 cvxCrvStakedBalance = cvxCrvStaker.balanceOf(address(this));
    cvxCrvStaker.withdraw(cvxCrvStakedBalance);
    cvxCrv.safeTransfer(receiver, cvxCrvStakedBalance);
  }

  /**
   * @notice Recover ERC2O tokens in the contract
   * @dev Recover ERC2O tokens in the contract
   * @param _token Address of the ERC2O token
   * @return bool: success
   */
  function recoverERC20(address _token) external onlyOwner returns (bool) {
    if (_token == address(cvxCrvStaker)) revert Errors.RecoverForbidden();

    if (_token == address(0)) revert Errors.ZeroAddress();
    uint256 amount = IERC20(_token).balanceOf(address(this));
    if (amount == 0) revert Errors.ZeroValue();

    IERC20(_token).safeTransfer(owner(), amount);

    return true;
  }
}