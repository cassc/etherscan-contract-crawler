// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import {ISapphireMapper} from "./ISapphireMapper.sol";
import {SafeMath} from "../lib/SafeMath.sol";

contract SapphireMapperLinear is ISapphireMapper {
    using SafeMath for uint256;

    /**
     * @notice An inverse linear mapper.
     * Returns `_upperBound - (_score * (_upperBound - _lowerBound)) / _scoreMax`
     *
     * @param _score The score to check for
     * @param _scoreMax The maximum score
     * @param _lowerBound The mapping lower bound
     * @param _upperBound The mapping upper bound
     */
    function map(
        uint256 _score,
        uint256 _scoreMax,
        uint256 _lowerBound,
        uint256 _upperBound
    )
        public
        virtual
        override
        view
        returns (uint256)
    {
        require(
            _scoreMax > 0,
            "SapphireMapperLinear: the maximum score cannot be 0"
        );

        require(
            _lowerBound < _upperBound,
            "SapphireMapperLinear: the lower bound must be less than the upper bound"
        );

        require(
            _score <= _scoreMax,
            "SapphireMapperLinear: the score cannot be larger than the maximum score"
        );

        uint256 boundsDifference = _upperBound.sub(_lowerBound);

        return _upperBound.sub(
            _score
                .mul(boundsDifference)
                .div(_scoreMax)
        );
    }

}