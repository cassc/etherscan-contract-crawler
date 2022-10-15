// SPDX-License-Identifier: BUSL-1.1

import "lib/openzeppelin-contracts-upgradeable/contracts/interfaces/IERC4626Upgradeable.sol";
import "lib/openzeppelin-contracts-upgradeable/contracts/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import { IWrappedfCashComplete } from "./external/notional/interfaces/IWrappedfCash.sol";

import "./interfaces/ISavingsVaultViewer.sol";

pragma solidity 0.8.13;

contract SavingsVaultPriceViewer {
    uint8 public constant BASE_DECIMALS = 6;
    uint8 public constant FCASH_DECIMALS = 8;
    uint8 public constant USV_DECIMALS = 18;

    function getPrice(address _savingsVault) external view returns (uint256) {
        address[2] memory fCashPositions = ISavingsVaultViewer(_savingsVault).getfCashPositions();
        uint assets = IERC20MetadataUpgradeable(IERC4626Upgradeable(_savingsVault).asset()).balanceOf(_savingsVault);
        for (uint i = 0; i < 2; i++) {
            IWrappedfCashComplete fCashPosition = IWrappedfCashComplete(fCashPositions[i]);
            uint fCashBalance = fCashPosition.balanceOf(address(_savingsVault));
            if (fCashBalance != 0) {
                if (fCashPosition.hasMatured()) {
                    assets += fCashPosition.convertToAssets(fCashBalance);
                } else {
                    assets += fCashBalance / 10**(FCASH_DECIMALS - BASE_DECIMALS);
                }
            }
        }
        return
            (assets * 10**(USV_DECIMALS - BASE_DECIMALS + FCASH_DECIMALS)) /
            IERC4626Upgradeable(_savingsVault).totalSupply();
    }
}