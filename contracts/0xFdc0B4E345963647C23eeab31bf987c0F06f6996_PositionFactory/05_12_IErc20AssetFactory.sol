pragma solidity ^0.8.17;
interface IErc20AssetFactory {
    function setAsset(
        uint256 positionId,
        uint256 assetCode,
        address contractAddress
    ) external;
}