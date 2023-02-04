// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import 'contracts/position_trading/assets/AssetsControllerBase.sol';

contract EthAssetsController is AssetsControllerBase {
    constructor(address positionsController)
        AssetsControllerBase(positionsController)
    {}

    receive() external payable {}

    function assetTypeId() external pure returns (uint256) {
        return 1;
    }

    function initialize(
        address from,
        uint256 assetId,
        AssetCreationData calldata data
    ) external payable onlyBuildMode(assetId) returns (uint256 ethSurplus) {
        uint256 ethConsumed;
        if (data.value > 0)
            (, ethConsumed) = _transferToAsset(assetId, from, data.value);

        // revert eth surplus
        ethSurplus = msg.value - ethConsumed;
        if (ethSurplus > 0) {
            (bool surplusSent, ) = msg.sender.call{ value: ethSurplus }('');
            require(surplusSent, 'ethereum surplus is not sent');
        }
    }

    function value(uint256 assetId) external pure returns (uint256) {
        return 0;
    }

    function contractAddr(uint256 assetId) external view returns (address) {
        return address(0);
    }

    function clone(uint256 assetId, address owner)
        external
        returns (ItemRef memory)
    {
        ItemRef memory newAsset = ItemRef(
            address(this),
            _positionsController.createNewAssetId()
        );
        _algorithms[newAsset.id] = owner;
        return newAsset;
    }

    function _withdraw(
        uint256 assetId,
        address recepient,
        uint256 count
    ) internal override {
        (bool sent, ) = payable(recepient).call{ value: count }('');
        require(sent, 'sent ether error: ether is not sent');
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
        require(msg.value >= count, 'not enouth eth');
        _counts[assetId] += count;
        ethConsumed = count;
        countTransferred = count;
    }
}