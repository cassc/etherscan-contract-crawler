// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./mellow-vaults/interfaces/vaults/IPancakeSwapVault.sol";

import "./mellow-vaults/interfaces/external/pancakeswap/INonfungiblePositionManager.sol";
import "./mellow-vaults/interfaces/external/pancakeswap/IPancakeV3Pool.sol";
import "./mellow-vaults/interfaces/external/pancakeswap/IPancakeV3Factory.sol";
import "./mellow-vaults/interfaces/external/pancakeswap/libraries/PositionValue.sol";

import "./IBaseFeesCollector.sol";

contract PancakeFeesCollector is IBaseFeesCollector {
    INonfungiblePositionManager public immutable positionManager;
    IPancakeV3Factory public immutable factory;

    constructor(INonfungiblePositionManager positionManager_) {
        positionManager = positionManager_;
        factory = IPancakeV3Factory(positionManager.factory());
    }

    function collectFeesData(
        address vault
    ) external view override returns (address[] memory tokens, uint256[] memory amounts) {
        tokens = new address[](2);
        amounts = new uint256[](2);
        uint256 positionNft = IPancakeSwapVault(vault).uniV3Nft();

        (, , address token0, address token1, , , , , , , , ) = positionManager.positions(positionNft);
        (amounts[0], amounts[1]) = PositionValue.fees(positionManager, positionNft);

        tokens[0] = token0;
        tokens[1] = token1;
    }
}