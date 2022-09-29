pragma solidity ^0.8.17;
interface IErc721ItemAssetFactory {
    function setAsset(
        uint256 positionId,
        uint256 assetCode,
        address contractAddress,
        uint256 tokenId
    ) external;
}