pragma solidity ^0.8.0;

import "../lending/PositionBondLending.sol";

interface IPositionBondFunction {
    function verifyRequire(
        PositionBondLending.BondInformation memory bondInformation,
        PositionBondLending.AssetInformation memory assetInformation
    ) external view returns (bool);

    function verifyAddCollateral(
        uint256[] memory amountTransferAdded,
        uint256 underlyingAssetType
    ) external view returns (bool);

    function verifyRemoveCollateral(
        uint256[] memory amountTransferRemoved,
        uint256[] memory nftIds,
        uint256 underlyingAmount,
        uint256 underlyingAssetType
    ) external view returns (uint256);

    function getTokenMapped(address nft) external view returns (address);

    function getPosiNFTFactory() external view returns (address);

    function getParValue(uint256[] memory nftIds)
        external
        view
        returns (uint256 totalParAmount);
}