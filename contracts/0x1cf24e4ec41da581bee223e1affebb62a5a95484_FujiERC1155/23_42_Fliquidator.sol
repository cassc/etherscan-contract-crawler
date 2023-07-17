// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

import { IVault} from "./Vaults/IVault.sol";
import { IFujiAdmin } from "./IFujiAdmin.sol";
import { IFujiERC1155} from "./FujiERC1155/IFujiERC1155.sol";
import { IERC20 } from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import { Flasher } from "./Flashloans/Flasher.sol";
import { FlashLoan } from "./Flashloans/LibFlashLoan.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Errors} from "./Libraries/Errors.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { UniERC20 } from "./Libraries/LibUniERC20.sol";
import { IUniswapV2Router02} from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import { ReentrancyGuard } from '@openzeppelin/contracts/utils/ReentrancyGuard.sol';

import "hardhat/console.sol";

interface IVaultExt is IVault {

  //Asset Struct
  struct VaultAssets {
    address collateralAsset;
    address borrowAsset;
    uint64 collateralID;
    uint64 borrowID;
  }

  function vAssets() external view returns(VaultAssets memory);

}

contract Fliquidator is Ownable, ReentrancyGuard {

  using SafeMath for uint256;
  using UniERC20 for IERC20;

  struct Factor {
    uint64 a;
    uint64 b;
  }

  // Flash Close Fee Factor
  Factor public flashCloseF;

  IFujiAdmin private _fujiAdmin;
  IUniswapV2Router02 public swapper;

  // Log Liquidation
  event LogLiquidate(address indexed userAddr, address liquidator, address indexed asset, uint256 amount);
  // Log FlashClose
  event LogFlashClose(address indexed userAddr, address indexed asset, uint256 amount);
  // Log Liquidation
  event LogFlashLiquidate(address userAddr, address liquidator, address indexed asset, uint256 amount);

  modifier isAuthorized() {
    require(
      msg.sender == owner() ||
      msg.sender == address(this),
      Errors.VL_NOT_AUTHORIZED);
    _;
  }

  modifier onlyFlash() {
    require(
      msg.sender == _fujiAdmin.getFlasher(),
      Errors.VL_NOT_AUTHORIZED
    );
    _;
  }

  constructor() public {

    // 1.013
    flashCloseF.a = 1013;
    flashCloseF.b = 1000;

  }

  receive() external payable {}

  // FLiquidator Core Functions

  /**
  * @dev Liquidate an undercollaterized debt and get bonus (bonusL in Vault)
  * @param _userAddr: Address of user whose position is liquidatable
  * @param _vault: Address of the vault in where liquidation will occur
  */
  function liquidate(address _userAddr, address _vault) external {

    // Update Balances at FujiERC1155
    IVault(_vault).updateF1155Balances();

    // Create Instance of FujiERC1155
    IFujiERC1155 F1155 = IFujiERC1155(IVault(_vault).fujiERC1155());

    // Struct Instance to get Vault Asset IDs in F1155
    IVaultExt.VaultAssets memory vAssets = IVaultExt(_vault).vAssets();

    // Get user Collateral and Debt Balances
    uint256 userCollateral = F1155.balanceOf(_userAddr, vAssets.collateralID);
    uint256 userDebtBalance = F1155.balanceOf(_userAddr, vAssets.borrowID);

    // Compute Amount of Minimum Collateral Required including factors
    uint256 neededCollateral = IVault(_vault).getNeededCollateralFor(userDebtBalance, true);

    // Check if User is liquidatable
    require(
      userCollateral < neededCollateral,
      Errors.VL_USER_NOT_LIQUIDATABLE
    );

    // Check Liquidator Allowance
    require(
      IERC20(vAssets.borrowAsset).allowance(msg.sender, address(this)) >= userDebtBalance,
      Errors.VL_MISSING_ERC20_ALLOWANCE
    );

    // Transfer borrowAsset funds from the Liquidator to Here
    IERC20(vAssets.borrowAsset).transferFrom(msg.sender, address(this), userDebtBalance);

    // Transfer Amount to Vault
    IERC20(vAssets.borrowAsset).transfer(_vault, userDebtBalance);

    // TODO: Get => corresponding amount of BaseProtocol Debt and FujiDebt

    // Repay BaseProtocol debt
    IVault(_vault).payback(int256(userDebtBalance));

    //TODO: Transfer corresponding Debt Amount to Fuji Treasury

    // Burn Debt F1155 tokens
    F1155.burn(_userAddr, vAssets.borrowID, userDebtBalance);

    // Compute the Liquidator Bonus bonusL
    uint256 bonus = IVault(_vault).getLiquidationBonusFor(userDebtBalance, false);
    // Compute how much collateral needs to be swapt
    uint256 collateralInPlay = getCollateralInPlay(vAssets.borrowAsset, userDebtBalance.add(bonus));

    // Withdraw collateral
    IVault(_vault).withdraw(int256(collateralInPlay));

    // Swap Collateral
    swap(vAssets.borrowAsset, userDebtBalance.add(bonus), collateralInPlay);

    // Burn Collateral F1155 tokens
    F1155.burn(_userAddr, vAssets.collateralID, collateralInPlay);

    // Transfer to Liquidator the debtBalance + bonus
    IERC20(vAssets.borrowAsset).uniTransfer(msg.sender, userDebtBalance.add(bonus));

    // Transfer left-over collateral to user
    //IERC20(vAssets.collateralAsset).uniTransfer(payable(_userAddr), remainingCollat);

    emit LogLiquidate(_userAddr, msg.sender, vAssets.borrowAsset, userDebtBalance);
  }

  /**
  * @dev Initiates a flashloan used to repay partially or fully the debt position of msg.sender
  * @param _amount: Pass -1 to fully close debt position, otherwise Amount to be repaid with a flashloan
  * @param _vault: The vault address where the debt position exist.
  * @param _flashnum: integer identifier of flashloan provider
  */
  function flashClose(int256 _amount, address _vault, uint8 _flashnum) external nonReentrant {

    Flasher flasher = Flasher(payable(_fujiAdmin.getFlasher()));

    // Update Balances at FujiERC1155
    IVault(_vault).updateF1155Balances();

    // Create Instance of FujiERC1155
    IFujiERC1155 F1155 = IFujiERC1155(IVault(_vault).fujiERC1155());

    // Struct Instance to get Vault Asset IDs in F1155
    IVaultExt.VaultAssets memory vAssets = IVaultExt(_vault).vAssets();

    // Get user  Balances
    uint256 userCollateral = F1155.balanceOf(msg.sender, vAssets.collateralID);
    uint256 userDebtBalance = F1155.balanceOf(msg.sender, vAssets.borrowID);

    // Check Debt is > zero
    require(userDebtBalance > 0, Errors.VL_NO_DEBT_TO_PAYBACK);

    uint256 amount = _amount < 0 ? userDebtBalance : uint256(_amount);

    uint256 neededCollateral = IVault(_vault).getNeededCollateralFor(amount, false);
    require(userCollateral >= neededCollateral, Errors.VL_UNDERCOLLATERIZED_ERROR);

    FlashLoan.Info memory info = FlashLoan.Info({
      callType: FlashLoan.CallType.Close,
      asset: vAssets.borrowAsset,
      amount: amount,
      vault: _vault,
      newProvider: address(0),
      user: msg.sender,
      userliquidator: address(0),
      fliquidator: address(this)
    });

    flasher.initiateFlashloan(info, _flashnum);
  }

  /**
  * @dev Close user's debt position by using a flashloan
  * @param _userAddr: user addr to be liquidated
  * @param _vault: Vault address
  * @param _amount: amount received by Flashloan
  * @param _flashloanFee: amount extra charged by flashloan provider
  * Emits a {LogFlashClose} event.
  */
  function executeFlashClose(
    address payable _userAddr,
    address _vault,
    uint256 _amount,
    uint256 _flashloanFee
  ) external onlyFlash {
    // Create Instance of FujiERC1155
    IFujiERC1155 F1155 = IFujiERC1155(IVault(_vault).fujiERC1155());

    // Struct Instance to get Vault Asset IDs in F1155
    IVaultExt.VaultAssets memory vAssets = IVaultExt(_vault).vAssets();

    // Get user Collateral and Debt Balances
    uint256 userCollateral = F1155.balanceOf(_userAddr, vAssets.collateralID);
    uint256 userDebtBalance = F1155.balanceOf(_userAddr, vAssets.borrowID);

    // Get user Collateral + Flash Close Fee to close posisition, for _amount passed
    uint256 userCollateralinPlay = IVault(_vault)
      .getNeededCollateralFor(_amount.add(_flashloanFee), false)
      .mul(flashCloseF.a).div(flashCloseF.b);

    // TODO: Get => corresponding amount of BaseProtocol Debt and FujiDebt

    // Repay BaseProtocol debt
    IVault(_vault).payback(int256(_amount));

    //TODO: Transfer corresponding Debt Amount to Fuji Treasury

    // Full close
    if (_amount == userDebtBalance) {
      F1155.burn(_userAddr, vAssets.collateralID, userCollateral);

      // Withdraw Full collateral
      IVault(_vault).withdraw(int256(userCollateral));

      // Send unUsed Collateral to User
      _userAddr.transfer(userCollateral.sub(userCollateralinPlay));
    }
    else {
      F1155.burn(_userAddr, vAssets.collateralID, userCollateralinPlay);

      // Withdraw Collateral in play Only
      IVault(_vault).withdraw(int256(userCollateralinPlay));
    }

    // Swap Collateral for underlying to repay Flashloan
    uint256 remaining = swap(vAssets.borrowAsset, _amount.add(_flashloanFee), userCollateralinPlay);

    // Send FlashClose Fee to FujiTreasury
    IERC20(vAssets.collateralAsset).uniTransfer(_fujiAdmin.getTreasury(), remaining);

    // Send flasher the underlying to repay Flashloan
    IERC20(vAssets.borrowAsset).uniTransfer(payable(_fujiAdmin.getFlasher()), _amount.add(_flashloanFee));

    // Burn Debt F1155 tokens
    F1155.burn(_userAddr, vAssets.borrowID, _amount);

    emit LogFlashClose(_userAddr, vAssets.borrowAsset, userDebtBalance);
  }

  /**
  * @dev Initiates a flashloan to liquidate an undercollaterized debt position,
  * gets bonus (bonusFlashL in Vault)
  * @param _userAddr: Address of user whose position is liquidatable
  * @param _vault: The vault address where the debt position exist.
  * @param _flashnum: integer identifier of flashloan provider
  */
  function flashLiquidate(address _userAddr, address _vault, uint8 _flashnum) external nonReentrant {

    // Update Balances at FujiERC1155
    IVault(_vault).updateF1155Balances();

    // Create Instance of FujiERC1155
    IFujiERC1155 F1155 = IFujiERC1155(IVault(_vault).fujiERC1155());

    // Struct Instance to get Vault Asset IDs in F1155
    IVaultExt.VaultAssets memory vAssets = IVaultExt(_vault).vAssets();

    // Get user Collateral and Debt Balances
    uint256 userCollateral = F1155.balanceOf(_userAddr, vAssets.collateralID);
    uint256 userDebtBalance = F1155.balanceOf(_userAddr, vAssets.borrowID);

    // Compute Amount of Minimum Collateral Required including factors
    uint256 neededCollateral = IVault(_vault).getNeededCollateralFor(userDebtBalance, true);

    // Check if User is liquidatable
    require(
      userCollateral < neededCollateral,
      Errors.VL_USER_NOT_LIQUIDATABLE
    );

    Flasher flasher = Flasher(payable(_fujiAdmin.getFlasher()));

    FlashLoan.Info memory info = FlashLoan.Info({
      callType: FlashLoan.CallType.Liquidate,
      asset: vAssets.borrowAsset,
      amount: userDebtBalance,
      vault: _vault,
      newProvider: address(0),
      user: _userAddr,
      userliquidator: msg.sender,
      fliquidator: address(this)
    });

    flasher.initiateFlashloan(info, _flashnum);
  }

  /**
  * @dev Liquidate a debt position by using a flashloan
  * @param _userAddr: user addr to be liquidated
  * @param _liquidatorAddr: liquidator address
  * @param _vault: Vault address
  * @param _amount: amount of debt to be repaid
  * @param _flashloanFee: amount extra charged by flashloan provider
  * Emits a {LogFlashLiquidate} event.
  */
  function executeFlashLiquidation(
    address _userAddr,
    address _liquidatorAddr,
    address _vault,
    uint256 _amount,
    uint256 _flashloanFee
  ) external onlyFlash {

    // Create Instance of FujiERC1155
    IFujiERC1155 F1155 = IFujiERC1155(IVault(_vault).fujiERC1155());

    // Struct Instance to get Vault Asset IDs in F1155
    IVaultExt.VaultAssets memory vAssets = IVaultExt(_vault).vAssets();

    // Get user Collateral and Debt Balances
    uint256 userCollateral = F1155.balanceOf(_userAddr, vAssets.collateralID);
    uint256 userDebtBalance = F1155.balanceOf(_userAddr, vAssets.borrowID);

    // TODO: Get => corresponding amount of BaseProtocol Debt and FujiDebt

    //TODO: Transfer corresponding Debt Amount to Fuji Treasury

    // Repay BaseProtocol debt to release collateral
    IVault(_vault).payback(int256(_amount));

    // Withdraw collateral
    IVault(_vault).withdraw(int256(userCollateral));

    // Compute the Liquidator Bonus bonusFlashL
    uint256 bonus = IVault(_vault).getLiquidationBonusFor(userDebtBalance, true);
    // Compute how much collateral needs to be swapt
    uint256 collateralInPlay = getCollateralInPlay(vAssets.borrowAsset, userDebtBalance.add(_flashloanFee).add(bonus));

    uint256 remainingCollat = swap(
      vAssets.borrowAsset,
      _amount.add(_flashloanFee).add(bonus),
      collateralInPlay
    );
    console.log(remainingCollat);

    // Send flasher the underlying to repay Flashloan
    IERC20(vAssets.borrowAsset).uniTransfer(payable(_fujiAdmin.getFlasher()), _amount.add(_flashloanFee));

    // Transfer Bonus bonusFlashL to liquidator
    IERC20(vAssets.borrowAsset).uniTransfer(payable(_liquidatorAddr), bonus);

    // Transfer left-over collateral to user
    //IERC20(vAssets.collateralAsset).uniTransfer(payable(_userAddr), remainingCollat);

    // Burn Debt F1155 tokens
    F1155.burn(_userAddr, vAssets.borrowID, userDebtBalance);

    // Burn Collateral F1155 tokens
    F1155.burn(_userAddr, vAssets.collateralID, collateralInPlay);

    emit LogFlashLiquidate(_userAddr, _liquidatorAddr, vAssets.borrowAsset, userDebtBalance);
  }

  /**
  * @dev Swap an amount of underlying
  * @param _borrowAsset: Address of vault borrowAsset
  * @param _amountToReceive: amount of underlying to receive
  * @param _collateralAmount: collateral Amount sent for swap
  */
  function swap(address _borrowAsset, uint256 _amountToReceive, uint256 _collateralAmount) internal returns(uint256) {

    // Swap Collateral Asset to Borrow Asset
    address[] memory path = new address[](2);
    path[0] = swapper.WETH();
    path[1] = _borrowAsset;
    uint[] memory swapperAmounts = swapper.swapETHForExactTokens{ value: _collateralAmount }(
      _amountToReceive,
      path,
      address(this),
      block.timestamp
    );

    return _collateralAmount.sub(swapperAmounts[0]);
  }

  /**
  * @dev Get exact amount of collateral to be swapt
  * @param _borrowAsset: Address of vault borrowAsset
  * @param _amountToReceive: amount of underlying to receive
  */
  function getCollateralInPlay(address _borrowAsset, uint256 _amountToReceive) internal view returns(uint256) {

    address[] memory path = new address[](2);
    path[0] = swapper.WETH();
    path[1] = _borrowAsset;
    uint[] memory amounts = swapper.getAmountsIn(_amountToReceive, path);

    return amounts[0];
  }

  // Administrative functions

  /**
  * @dev Set Factors "a" and "b" for a Struct Factor flashcloseF
  * For flashCloseF;  should be > 1, a/b
  * @param _newFactorA: A number
  * @param _newFactorB: A number
  */
  function setFlashCloseFee(uint64 _newFactorA, uint64 _newFactorB) external isAuthorized {
    flashCloseF.a = _newFactorA;
    flashCloseF.b = _newFactorB;
  }

  /**
  * @dev Sets the fujiAdmin Address
  * @param _newFujiAdmin: FujiAdmin Contract Address
  */
  function setFujiAdmin(address _newFujiAdmin) public isAuthorized{
    _fujiAdmin = IFujiAdmin(_newFujiAdmin);
  }

  /**
  * @dev Changes the Swapper contract address
  * @param _newSwapper: address of new swapper contract
  */
  function setSwapper(address _newSwapper) external isAuthorized {
    swapper = IUniswapV2Router02(_newSwapper);
  }


}