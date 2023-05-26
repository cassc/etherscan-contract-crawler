pragma solidity 0.5.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../public/contracts/base/interface/IVault.sol";
import "./interface/INotifyHelper.sol";
import "../public/contracts/base/snx-base/interfaces/SNXRewardInterface.sol";
import "./interface/IFarmAutostake.sol";

import "../public/contracts/base/StrategyBase.sol";

/**
* This strategy is for the FARM token
*/
contract iFarmStrategy is StrategyBase {

  using SafeERC20 for IERC20;
  using Address for address;
  using SafeMath for uint256;

  IFarmAutostake public farmAutostake;
  address public farm = address(0xa0246c9032bC3A600820415aE600c6388619A14D);
  address public notifyHelperAddress;

  constructor(
    address _storage,
    address _vault,
    address _farmAutostake
  )
  StrategyBase(_storage, farm, _vault, farm, address(0)) public {
    require(IVault(_vault).underlying() == farm, "vault does not support Farm");
    farmAutostake = IFarmAutostake(_farmAutostake);
    notifyHelperAddress = address(0);
  }

  function depositArbCheck() public view returns(bool) {
    return true;
  }

  function salvage(address recipient, address token, uint256 amount) public onlyGovernance {
    // To make sure that governance cannot come in and take away the coins
    require(!unsalvagableTokens[token], "token is defined as not salvageable");
    IERC20(token).safeTransfer(recipient, amount);
  }

  /**
  * Withdraws the underlying tokens to the vault in the specified amount.
  */
  function withdrawToVault(uint256 amountUnderlying) external restricted {
    farmAutostake.exit();
    require(IERC20(farm).balanceOf(address(this)) >= amountUnderlying, "insufficient balance for the withdrawal");
    IERC20(farm).safeTransfer(vault, amountUnderlying);
    investAllUnderlying();
  }

  /**
  * Withdraws all the underlying tokens to the vault.
  */
  function withdrawAllToVault() external restricted {
    farmAutostake.exit();
    uint256 balance = IERC20(farm).balanceOf(address(this));
    if (balance > 0) {
      IERC20(farm).safeTransfer(vault, balance);
    }
  }

  /**
  * Returns all underlying balance.
  */
  function investedUnderlyingBalance() public view returns (uint256) {
    return farmAutostake.balanceOf(address(this)).add(
      IERC20(farm).balanceOf(address(this))
    );
  }

  function refreshAutoStaking() public restricted {
    farmAutostake.refreshAutoStake();
  }

  /**
  * Simply calls refreshAutoStake() on the Autostake contract.
  */
  function doHardWork() public restricted {
    if (!investAllUnderlying()) {
      farmAutostake.refreshAutoStake();
    }
    if (notifyHelperAddress != address(0)) {
      // additional daily emissions
      INotifyHelper(notifyHelperAddress).notifyProfitSharing();
    }
  }

  function setNotifyHelperAddress(address _newAddress) public onlyGovernance {
    // address(0) is allowed
    notifyHelperAddress = _newAddress;
  }

  function investAllUnderlying() public restricted returns (bool) {
    if(IERC20(farm).balanceOf(address(this)) > 0){
      // stake back to the Autostake
      IERC20(farm).safeApprove(address(farmAutostake), 0);
      IERC20(farm).safeApprove(address(farmAutostake), IERC20(farm).balanceOf(address(this)));
      farmAutostake.stake(IERC20(farm).balanceOf(address(this)));
      return true;
    }
    return false;
  }
}