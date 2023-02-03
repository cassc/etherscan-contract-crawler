// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import 'contracts/position_trading/algorithms/TradingPair/TradingPairData.sol';
import 'contracts/position_trading/algorithms/TradingPair/ITradingPairAlgorithm.sol';
import 'contracts/position_trading/algorithms/TradingPair/ITradingPairFeeDistributer.sol';
import 'contracts/lib/erc20/Erc20ForFactory.sol';
import 'contracts/position_trading/IPositionsController.sol';
import 'contracts/position_trading/algorithms/TradingPair/FeeSettings.sol';

contract TradingPairReader {
    ITradingPairAlgorithm public algorithm;

    constructor(address algorithm_) {
        algorithm = ITradingPairAlgorithm(algorithm_);
    }

    function getTradingPair(uint256 positionId)
        external
        view
        returns (TradingPairData memory)
    {
        IPositionsController positionsController = IPositionsController(
            algorithm.getPositionsController()
        );

        TradingPairData memory data;

        data.positionId = positionId;
        data.owner = positionsController.ownerOf(positionId);

        data.liquidityToken = algorithm.getLiquidityToken(positionId);
        data.liquidityTokenTotalSupply = Erc20ForFactory(data.liquidityToken)
            .totalSupply();

        data.feeSettings = algorithm.getFeeSettings(positionId);
        data.feeToken = algorithm.getFeeToken(positionId);
        data.feeTokenTotalSupply = Erc20ForFactory(data.feeToken).totalSupply();

        data.feeDistributer = algorithm.getFeeDistributer(positionId);
        (
            uint256 feeDistributerAsset1Count,
            uint256 feeDistributerAsset2Count
        ) = ITradingPairFeeDistributer(data.feeDistributer).allAssetsCounts();
        data.feeDistributerAsset1Count = feeDistributerAsset1Count;
        data.feeDistributerAsset2Count = feeDistributerAsset2Count;

        data.asset1 = positionsController.getAsset(positionId, 1);
        data.asset2 = positionsController.getAsset(positionId, 2);

        require(
            data.asset1.id > 0 && data.asset2.id > 0,
            'position is not exists'
        );

        return data;
    }
}