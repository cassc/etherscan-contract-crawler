// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import 'contracts/position_trading/assets/AssetsControllerBase.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';

struct Erc721AssetData {
    IERC721 erc721;
    uint256 tokenId;
}

contract Erc721ItemAssetsController is AssetsControllerBase {
    mapping(uint256 => Erc721AssetData) _data;

    constructor(address positionsController)
        AssetsControllerBase(positionsController)
    {}

    function assetTypeId() external pure returns (uint256) {
        return 3;
    }

    function initialize(
        address from,
        uint256 assetId,
        AssetCreationData calldata data
    ) external payable onlyBuildMode(assetId) returns (uint256 ethSurplus) {
        ethSurplus = msg.value;
        _data[assetId] = Erc721AssetData(
            IERC721(data.contractAddress),
            data.value
        );
        if (data.value > 0) _transferToAsset(assetId, from, data.value);

        // revert eth surplus
        if (ethSurplus > 0) {
            (bool surplusSent, ) = msg.sender.call{ value: ethSurplus }('');
            require(surplusSent, 'ethereum surplus is not sent');
        }
    }

    function value(uint256 assetId) external view returns (uint256) {
        return _data[assetId].tokenId;
    }

    function contractAddr(uint256 assetId) external view returns (address) {
        return address(_data[assetId].erc721);
    }

    function clone(uint256 assetId, address owner)
        external
        returns (ItemRef memory)
    {
        ItemRef memory newAsset = ItemRef(
            address(this),
            _positionsController.createNewAssetId()
        );
        _data[newAsset.id] = _data[assetId];
        _algorithms[newAsset.id] = owner;
        return newAsset;
    }

    function _withdraw(
        uint256 assetId,
        address recepient,
        uint256 count
    ) internal override {
        _data[assetId].erc721.transferFrom(
            address(this),
            recepient,
            _data[assetId].tokenId
        );
    }

    function _transferToAsset(
        uint256 assetId,
        address from,
        uint256 count
    )
        internal
        override
        returns (uint256 countTransferred, uint256 ethConsumed)
    {
        ethConsumed = 0;
        _data[assetId].erc721.transferFrom(
            from,
            address(this),
            _data[assetId].tokenId
        );
        _counts[assetId] = 1;
        countTransferred = 1;
    }
}