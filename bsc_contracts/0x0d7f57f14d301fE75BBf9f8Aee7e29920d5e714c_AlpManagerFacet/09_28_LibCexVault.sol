// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {LibVault} from  "../libraries/LibVault.sol";
import {ICexAsset} from "../../dependencies/ICexAsset.sol";
import {LibPriceFacade} from  "../libraries/LibPriceFacade.sol";

library LibCexVault {

    bytes32 constant CEX_VAULT_STORAGE_POSITION = keccak256("apollox.cex.vault.storage");
    uint16 constant  RATE_BASE = 10000;

    struct CexVaultStorage {
        address cexOracle;
        uint16 securityMarginRate;
    }

    function cexVaultStorage() internal pure returns (CexVaultStorage storage cvs) {
        bytes32 position = CEX_VAULT_STORAGE_POSITION;
        assembly {
            cvs.slot := position
        }
    }

    function initialize(address cexOracle, uint16 securityMarginRate) internal {
        CexVaultStorage storage cvs = cexVaultStorage();
        require(cvs.cexOracle == address(0), "LibCexVault: Already initialized");
        cvs.cexOracle = cexOracle;
        cvs.securityMarginRate = securityMarginRate;
    }

    event SetSecurityMarginRate(uint16 oldRate, uint16 newRate);

    function updateCexOracle(address cexOracle) internal {
        CexVaultStorage storage cvs = cexVaultStorage();
        cvs.cexOracle = cexOracle;
    }

    function setSecurityMarginRate(uint16 securityMarginRate) internal {
        CexVaultStorage storage cvs = cexVaultStorage();
        uint16 oldRate = cvs.securityMarginRate;
        cvs.securityMarginRate = securityMarginRate;
        emit SetSecurityMarginRate(oldRate, securityMarginRate);
    }

    function getCexTotalValueUsd() internal view returns (int256 totalValueUsd, uint256 blockNo) {
        CexVaultStorage storage cvs = cexVaultStorage();
        ICexAsset.BatchAssetRecord memory assetRecord;
        for (uint8 i; i < 5;) {
            assetRecord = ICexAsset(cvs.cexOracle).getRecordsAtIndex(i);
            if (assetRecord.blockNumber != block.number) {
                break;
            }
            unchecked {
                i++;
            }
        }
        require(assetRecord.blockNumber != block.number, "LibCexVault: Lack of historical data");
        LibVault.VaultStorage storage vs = LibVault.vaultStorage();
        ICexAsset.AssetDetailRecord[] memory assetRecords = assetRecord.records;
        for (uint256 i; i < assetRecords.length;) {
            ICexAsset.AssetDetailRecord memory asset = assetRecords[i];
            LibVault.AvailableToken storage at = vs.tokens[asset.symbol];
            if (at.weight > 0 &&
                (asset.assetType == ICexAsset.AssetType.AssetBalance || asset.assetType == ICexAsset.AssetType.UnRealizedPnl)) {
                uint256 price = LibPriceFacade.getPrice(asset.symbol);
                int256 valueUsd = int256(price) * int256(asset.balance) * int256((10 ** LibPriceFacade.USD_DECIMALS)) / int256((10 ** (LibPriceFacade.PRICE_DECIMALS + at.decimals)));
                totalValueUsd += valueUsd;
            }
            unchecked {
                i++;
            }
        }
        return (totalValueUsd, assetRecord.blockNumber);
    }

    function getCexTokenValueUsd(address token) internal view returns (int256 tokenValueUsd) {
        CexVaultStorage storage cvs = cexVaultStorage();
        ICexAsset.AssetDetailRecord[] memory assetRecords = ICexAsset(cvs.cexOracle).getRecordsAtIndex(0).records;
        LibVault.VaultStorage storage vs = LibVault.vaultStorage();
        for (uint256 i; i < assetRecords.length;) {
            ICexAsset.AssetDetailRecord memory asset = assetRecords[i];
            LibVault.AvailableToken storage at = vs.tokens[asset.symbol];
            if (token == asset.symbol && at.weight > 0 &&
                (asset.assetType == ICexAsset.AssetType.AssetBalance || asset.assetType == ICexAsset.AssetType.UnRealizedPnl)) {
                uint256 price = LibPriceFacade.getPrice(asset.symbol);
                int256 valueUsd = int256(price) * int256(asset.balance) * int256((10 ** LibPriceFacade.USD_DECIMALS)) / int256((10 ** (LibPriceFacade.PRICE_DECIMALS + at.decimals)));
                tokenValueUsd += valueUsd;
            }
            unchecked {
                i++;
            }
        }
        return tokenValueUsd;
    }

    function lastBlockNumberPoint() internal view returns (uint256) {
        return ICexAsset(cexVaultStorage().cexOracle).getRecordsAtIndex(0).blockNumber;
    }

    function maxWithdrawAbleUsd() internal view returns (int256) {
        LibVault.VaultStorage storage vs = LibVault.vaultStorage();
        CexVaultStorage storage cvs = cexVaultStorage();
        ICexAsset.AssetDetailRecord[] memory assetRecords = ICexAsset(cvs.cexOracle).getRecordsAtIndex(0).records;
        uint256 totalpositionNotional;
        for (uint256 i; i < assetRecords.length;) {
            ICexAsset.AssetDetailRecord memory asset = assetRecords[i];
            LibVault.AvailableToken storage at = vs.tokens[asset.symbol];
            if (at.weight > 0 && asset.assetType == ICexAsset.AssetType.TotalNotional) {
                uint256 price = LibPriceFacade.getPrice(asset.symbol);
                totalpositionNotional += price * uint256(int256(asset.balance)) * (10 ** LibPriceFacade.USD_DECIMALS) / (10 ** (LibPriceFacade.PRICE_DECIMALS + at.decimals));
            }
            unchecked {
                i++;
            }
        }
        (int256 cexTotalAsset,) = getCexTotalValueUsd();
        return cexTotalAsset - int256(totalpositionNotional * cvs.securityMarginRate / LibCexVault.RATE_BASE);
    }
}