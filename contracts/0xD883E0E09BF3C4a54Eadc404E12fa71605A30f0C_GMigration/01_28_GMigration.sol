// SPDX-License-Identifier: AGPLv3
pragma solidity 0.8.10;

import {ERC20} from "ERC20.sol";
import {Ownable} from "Ownable.sol";
import {SafeTransferLib} from "SafeTransferLib.sol";
import {ICurve3Pool} from "ICurve3Pool.sol";
import {Constants} from "Constants.sol";
import {Errors} from "Errors.sol";
import {GTranche} from "GTranche.sol";
import {GVault} from "GVault.sol";
import {SeniorTranche} from "SeniorTranche.sol";

//  ________  ________  ________
//  |\   ____\|\   __  \|\   __  \
//  \ \  \___|\ \  \|\  \ \  \|\  \
//   \ \  \  __\ \   _  _\ \  \\\  \
//    \ \  \|\  \ \  \\  \\ \  \\\  \
//     \ \_______\ \__\\ _\\ \_______\
//      \|_______|\|__|\|__|\|_______|

// gro protocol: https://github.com/groLabs/GSquared

/// @title GMigration
/// @notice Responsible for migrating funds from old gro protocol to the new gro protocol
/// this contract converts stables to 3crv and then deposits into the new GVault which in turn
/// is deposited into the gTranche.
contract GMigration is Ownable, Constants {
    using SafeTransferLib for ERC20;

    address constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address constant THREE_POOL = 0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7;
    address constant THREE_POOL_TOKEN =
        0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490;
    address constant PWRD = 0xF0a93d4994B3d98Fb5e3A2F90dBc2d69073Cb86b;
    GVault immutable gVault;
    bool IsGTrancheSet;
    GTranche public gTranche;
    uint256 public seniorTrancheDollarAmount;

    constructor(GVault _gVault) {
        gVault = _gVault;
    }

    /// @notice Set address of gTranche
    /// @dev Needs to be set after deploying gTranche
    /// @param _gTranche address of gTranche
    function setGTranche(GTranche _gTranche) external onlyOwner {
        if (IsGTrancheSet) {
            revert Errors.TrancheAlreadySet();
        }
        gTranche = _gTranche;
        IsGTrancheSet = true;
    }

    /// @notice Migrates funds from old gro-protocol to new gro-protocol
    /// @dev assumes gMigration has all stables from old gro protocol
    /// @param minAmountThreeCRV minimum amount of 3crv expected from swapping all stables
    function prepareMigration(
        uint256 minAmountThreeCRV,
        uint256 minAmountShares
    ) external onlyOwner {
        if (!IsGTrancheSet) {
            revert Errors.TrancheNotSet();
        }

        // read senior tranche value before migration
        seniorTrancheDollarAmount = SeniorTranche(PWRD).totalAssets();

        uint256 DAI_BALANCE = ERC20(DAI).balanceOf(address(this));
        uint256 USDC_BALANCE = ERC20(USDC).balanceOf(address(this));
        uint256 USDT_BALANCE = ERC20(USDT).balanceOf(address(this));

        // approve three pool
        ERC20(DAI).safeApprove(THREE_POOL, DAI_BALANCE);
        ERC20(USDC).safeApprove(THREE_POOL, USDC_BALANCE);
        ERC20(USDT).safeApprove(THREE_POOL, USDT_BALANCE);

        // swap for 3crv
        ICurve3Pool(THREE_POOL).add_liquidity(
            [DAI_BALANCE, USDC_BALANCE, USDT_BALANCE],
            minAmountThreeCRV
        );

        //check 3crv amount received
        uint256 depositAmount = ERC20(THREE_POOL_TOKEN).balanceOf(
            address(this)
        );

        // approve 3crv for GVault
        ERC20(THREE_POOL_TOKEN).safeApprove(address(gVault), depositAmount);

        // deposit into GVault
        uint256 shareAmount = gVault.deposit(depositAmount, address(this));

        if (shareAmount < minAmountShares) revert Errors.InsufficientShares();
        // approve gVaultTokens for gTranche
        ERC20(address(gVault)).safeApprove(address(gTranche), shareAmount);
    }
}