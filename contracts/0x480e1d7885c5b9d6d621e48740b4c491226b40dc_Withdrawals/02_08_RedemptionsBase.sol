// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title RedemptionsBase - ERC20 token redemption base
/// @author @ChimeraDefi - sharedstake.org
/// @notice RedemptionsBase accepts an underlying ERC20 and redeems it for - child impl
/** @dev Deployer chooses static virtual price at launch in 1e18 and the underlying ERC20 token
Users call deposit(amt) to stake their ERC20 and signal intent to exit
When the contract has enough ETH to service the users debt
Users call redeem() to redem for ETH = deposited shares * virtualPrice
The user can further call withdraw() if they change their mind about redeeming for ETH
**/
contract RedemptionsBase is ReentrancyGuard {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  error ContractBalanceTooLow();
  error UserAmountIsZero();
  struct UserEntry {
    uint256 amount;
  }

  mapping(address => UserEntry) public userEntries;
  uint256 public totalOut;
  uint256 public immutable virtualPrice;
  IERC20 public immutable vEth2Token;

  constructor(address _underlying, uint256 _virtualPrice) payable {
    vEth2Token = IERC20(_underlying);
    virtualPrice = _virtualPrice;
  }

  function deposit(uint256 amount) external nonReentrant {
    // vEth2 transfer from returns true otherwise reverts
    if (vEth2Token.transferFrom(msg.sender, address(this), amount)) {
      _stakeForWithdrawal(msg.sender, amount);
    }
  }

  function withdraw() external nonReentrant {
    uint256 amt = userEntries[msg.sender].amount;
    delete userEntries[msg.sender];

    vEth2Token.transferFrom(address(this), msg.sender, amt);
  }

  function redeem() external nonReentrant {
    address usr = msg.sender;
    uint256 amountToReturn = _getAmountGivenShares(userEntries[usr].amount, virtualPrice);
    if (amountToReturn == 0) {
      revert UserAmountIsZero();
    }
    delete userEntries[usr];
    totalOut += amountToReturn;
    _redeem(amountToReturn);
  }

  function _redeem(uint256 amountToReturn) internal virtual { // solhint-disable-line
    require(false, "implement me");
  }

  function _stakeForWithdrawal(address sender, uint256 amount) internal {
    UserEntry memory ue = userEntries[sender];
    ue.amount = ue.amount.add(amount);
    userEntries[sender] = ue;
  }

  function _getAmountGivenShares(uint256 shares, uint256 _vp) internal pure returns (uint256) {
    return shares.mul(_vp).div(1e18);
  }

  receive() external payable {} // solhint-disable-line
  fallback() external payable {} // solhint-disable-line
}