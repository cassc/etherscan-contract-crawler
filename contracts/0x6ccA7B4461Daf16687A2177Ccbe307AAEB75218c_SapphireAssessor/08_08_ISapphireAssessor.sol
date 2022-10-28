// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import {SapphireTypes} from "./SapphireTypes.sol";

interface ISapphireAssessor {
    function getPassportScoresContract() external view returns (address);
    
    function assess(
        uint256 _lowerBound,
        uint256 _upperBound,
        SapphireTypes.ScoreProof calldata _scoreProof,
        bool _isScoreRequired
    )
        external
        returns (uint256);

    function assessBorrowLimit(
        uint256 _borrowedAmount,
        SapphireTypes.ScoreProof calldata _borrowLimitProof
    )
        external
        returns (bool);
}