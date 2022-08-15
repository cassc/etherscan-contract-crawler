// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface ICollats is IERC20Upgradeable {
    struct Rate {
        uint256 numerator;
        uint256 denominator;
    }

    struct BackupAsset {
        IERC20Upgradeable asset;
        Rate exchangeRate;
        uint256 decimals;
        bool isAllowed;
    }

    event MinterChanged(address indexed newMinter);

    event FeeChanged(uint256 numerator, uint256 denominator);

    event RedeemBackUpAssetChanged(BackupAsset newBackUpAsset);

    event BackupAssetModified(BackupAsset backupAssetModified);

    event BackupAssetAdded(BackupAsset backupAssetAdded);

    event CollatsMinted(
        address indexed to,
        uint256 minted,
        uint256 bought,
        uint256 feeAmount
    );

    event CollatsRedeemed(
        address indexed to,
        uint256 amount,
        uint256 decimals,
        address backUpAsset
    );

    function buyCollats() external payable returns (uint256 collatsBought);

    function buyCollatsWithERC20(address token, uint256 amount)
        external
        returns (uint256 collatsBought);

    function redeem(uint256 amountInWei)
        external
        returns (
            uint256 assetAmount,
            uint256 decimals,
            address asset
        );

    function redeemWithERC20(address token, uint256 amountInWei)
        external
        returns (
            uint256 assetAmount,
            uint256 decimals,
            address asset
        );

    function decimalFactor(uint256 _decimals) external pure returns (uint256);

    function getBackupAssets() external view returns (BackupAsset[] memory);

    function getBackupAsset(address token)
        external
        view
        returns (BackupAsset memory);

    function getAmountIn(address from, uint256 amountOut)
        external
        view
        returns (uint256 amountIn);

    function getAmountOut(address from, uint256 amountIn)
        external
        view
        returns (uint256 amountOut);

    function getVersion() external pure returns (uint256);
}