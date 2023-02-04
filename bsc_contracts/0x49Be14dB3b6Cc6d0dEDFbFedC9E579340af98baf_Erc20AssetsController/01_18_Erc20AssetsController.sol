// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import 'contracts/position_trading/assets/AssetsControllerBase.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

contract Erc20AssetsController is AssetsControllerBase {
    using SafeERC20 for IERC20;

    mapping(uint256 => IERC20) _contracts;

    constructor(address positionsController)
        AssetsControllerBase(positionsController)
    {}

    function assetTypeId() external pure returns (uint256) {
        return 2;
    }

    function initialize(
        address from,
        uint256 assetId,
        AssetCreationData calldata data
    ) external payable onlyBuildMode(assetId) returns (uint256 ethSurplus) {
        ethSurplus = msg.value;
        uint256[] memory arr;
        _contracts[assetId] = IERC20(data.contractAddress);
        if (data.value > 0) _transferToAsset(assetId, from, data.value);

        // revert eth surplus
        if (ethSurplus > 0) {
            (bool surplusSent, ) = msg.sender.call{ value: ethSurplus }('');
            require(surplusSent, 'ethereum surplus is not sent');
        }
    }

    function value(uint256 assetId) external pure returns (uint256) {
        return 0;
    }

    function contractAddr(uint256 assetId) external view returns (address) {
        return address(_contracts[assetId]);
    }

    function clone(uint256 assetId, address owner)
        external
        returns (ItemRef memory)
    {
        ItemRef memory newAsset = ItemRef(
            address(this),
            _positionsController.createNewAssetId()
        );
        _contracts[newAsset.id] = _contracts[assetId];
        _algorithms[newAsset.id] = owner;
        return newAsset;
    }

    function _withdraw(
        uint256 assetId,
        address recepient,
        uint256 count
    ) internal override {
        _contracts[assetId].safeTransfer(recepient, count);
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
        IERC20 token = _contracts[assetId];
        uint256 lastBalance = token.balanceOf(address(this));
        token.safeTransferFrom(from, address(this), count);
        countTransferred = token.balanceOf(address(this)) - lastBalance;
        _counts[assetId] += countTransferred;
    }
}