// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IDAOInvestors.sol";
import "./IMFToken.sol";
import "./IMFSwap.sol";

abstract contract BaseDAO {
    uint256 constant precision = 10 ** 4;

    function getProgress(
        uint256 _startDate,
        uint256 _duration
    ) public view returns (uint256) {
        if (_startDate > block.timestamp) return 0;

        uint256 dateDiff = block.timestamp - _startDate;
        if (dateDiff > _duration) {
            return precision;
        }

        uint256 progress = (dateDiff * precision) / _duration;
        return progress;
    }
}