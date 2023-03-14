// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.16;

import {ERC20} from "solmate/src/tokens/ERC20.sol";
import {SafeTransferLib} from "solmate/src/utils/SafeTransferLib.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

import {ILendingPool} from "src/interfaces/aave.sol";

import {AffineVault} from "src/vaults/AffineVault.sol";
import {BaseStrategy} from "./BaseStrategy.sol";

contract AaveV2Strategy is BaseStrategy {
    using SafeTransferLib for ERC20;

    /// @notice The lending pool. We'll call deposit, withdraw, etc. on this.
    ILendingPool public immutable lendingPool;
    /// @notice Corresponding AAVE asset (USDC -> aUSDC)
    ERC20 public immutable aToken;

    constructor(AffineVault _vault, ILendingPool _lendingPool) BaseStrategy(_vault) {
        lendingPool = _lendingPool;
        aToken = ERC20(lendingPool.getReserveData(address(asset)).aTokenAddress);

        // We can mint/burn aTokens
        asset.safeApprove(address(lendingPool), type(uint256).max);
        aToken.safeApprove(address(lendingPool), type(uint256).max);
    }

    /*//////////////////////////////////////////////////////////////
                               INVESTMENT
    //////////////////////////////////////////////////////////////*/
    function _afterInvest(uint256 amount) internal override {
        if (amount == 0) return;
        lendingPool.deposit(address(asset), amount, address(this), 0);
    }

    /*//////////////////////////////////////////////////////////////
                               DIVESTMENT
    //////////////////////////////////////////////////////////////*/
    function _divest(uint256 assets) internal override returns (uint256) {
        // Withdraw only the needed amounts from the lending pool
        uint256 currAssets = balanceOfAsset();
        uint256 assetsReq = currAssets >= assets ? 0 : assets - currAssets;

        // Don't try to withdraw more aTokens than we actually have
        if (assetsReq != 0) {
            uint256 assetsToWithdraw = Math.min(assetsReq, aToken.balanceOf(address(this)));
            lendingPool.withdraw(address(asset), assetsToWithdraw, address(this));
        }

        uint256 amountToSend = Math.min(assets, balanceOfAsset());
        asset.safeTransfer(address(vault), amountToSend);
        return amountToSend;
    }

    /*//////////////////////////////////////////////////////////////
                             TVL ESTIMATION
    //////////////////////////////////////////////////////////////*/
    function totalLockedValue() public view override returns (uint256) {
        return balanceOfAsset() + aToken.balanceOf(address(this));
    }
}