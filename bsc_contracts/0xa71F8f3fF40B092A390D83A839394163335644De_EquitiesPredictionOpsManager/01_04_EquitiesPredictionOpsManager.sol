// SPDX-License-Identifier: BSD-4-Clause

pragma solidity ^0.8.13;

import ".././Interface/IBhavishPrediction.sol";

import "@openzeppelin/contracts/access/Ownable.sol";

interface IBhavishEquitiesPrediction is IBhavishPrediction {
    function shouldExecuteRound() external view returns (bool);

    function isStartPredictionMarket() external view returns (bool);
}

contract EquitiesPredictionOpsManager is Ownable {
    IBhavishEquitiesPrediction[] public predictionMarkets;

    constructor(IBhavishEquitiesPrediction[] memory _bhavishPrediction) {
        for (uint256 i = 0; i < _bhavishPrediction.length; i++) {
            setPredicitionMarket(_bhavishPrediction[i]);
        }
    }

    function setPredicitionMarket(IBhavishEquitiesPrediction _bhavishPredicition) public onlyOwner {
        require(address(_bhavishPredicition) != address(0), "Invalid predicitions");

        predictionMarkets.push(_bhavishPredicition);
    }

    function removePredictionMarket(IBhavishPrediction _bhavishPrediction) public onlyOwner {
        require(address(_bhavishPrediction) != address(0), "Invalid predicitions");

        for (uint256 i = 0; i < predictionMarkets.length; i++) {
            if (predictionMarkets[i] == _bhavishPrediction) {
                predictionMarkets[i] = predictionMarkets[predictionMarkets.length - 1];
                predictionMarkets.pop();
                break;
            }
        }
    }

    /**
     * perform  task execution
     */
    function execute() public {
        for (uint256 i = 0; i < predictionMarkets.length; i++) {
            if (predictionMarkets[i].shouldExecuteRound() || predictionMarkets[i].isStartPredictionMarket()) {
                predictionMarkets[i].executeRound();
            }
        }
    }

    /**
     *checks the pre condition before executing op task
     */
    function canPerformTask() external view returns (bool canPerform) {
        for (uint256 i = 0; i < predictionMarkets.length; i++) {
            canPerform = predictionMarkets[i].shouldExecuteRound() || predictionMarkets[i].isStartPredictionMarket();
            if (canPerform) break;
        }
    }
}