pragma solidity ^0.8.17;
interface IEthAssetFactory {
    function setAsset(uint256 positionId, uint256 assetCode) external;
}