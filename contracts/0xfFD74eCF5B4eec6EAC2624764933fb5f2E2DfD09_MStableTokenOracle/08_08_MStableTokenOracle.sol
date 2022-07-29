// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "../../interfaces/external/mstable/IMasset.sol";
import "../../interfaces/external/mstable/ISavingsContractV2.sol";
import "../../interfaces/periphery/IOracle.sol";
import "../../interfaces/periphery/ITokenOracle.sol";

/**
 * @title mStable's tokens oracle
 */
contract MStableTokenOracle is ITokenOracle {
    uint256 private constant RATIO_DENOMINATOR = 1e8;

    IMasset public constant MUSD = IMasset(0xe2f2a5C287993345a840Db3B0845fbC70f5935a5);
    ISavingsContractV2 public constant IMUSD = ISavingsContractV2(0x30647a72Dc82d7Fbb1123EA74716aB8A317Eac19);
    IMasset public constant MBTC = IMasset(0x945Facb997494CC2570096c74b5F66A3507330a1);
    ISavingsContractV2 public constant IMBTC = ISavingsContractV2(0x17d8CBB6Bce8cEE970a4027d1198F6700A7a6c24);

    /// @inheritdoc ITokenOracle
    function getPriceInUsd(address mAsset_) external view returns (uint256) {
        if (mAsset_ == address(MUSD)) return _mAssetUsdPrice(MUSD);
        if (mAsset_ == address(IMUSD)) return (IMUSD.exchangeRate() * _mAssetUsdPrice(MUSD)) / 1e18;
        if (mAsset_ == address(MBTC)) return _mAssetUsdPrice(MBTC);
        if (mAsset_ == address(IMBTC)) return (IMBTC.exchangeRate() * _mAssetUsdPrice(MBTC)) / 1e18;

        revert("invalid-token");
    }

    /// @notice Return mAsset price
    /// @dev Uses the `MasterOracle` (msg.sender) to get underlying assets' prices
    function _mAssetUsdPrice(IMasset mAsset_) private view returns (uint256) {
        (IMasset.BassetPersonal[] memory bAssetPersonal, IMasset.BassetData[] memory bAssetData) = mAsset_.getBassets();
        uint256 _totalValue;
        uint256 _len = bAssetData.length;
        for (uint256 i; i < _len; i++) {
            _totalValue +=
                ((uint256(bAssetData[i].vaultBalance * bAssetData[i].ratio)) / RATIO_DENOMINATOR) *
                // Note: `msg.sender` is the `MasterOracle` contract
                IOracle(msg.sender).getPriceInUsd(bAssetPersonal[i].addr);
        }

        return _totalValue / mAsset_.totalSupply();
    }
}