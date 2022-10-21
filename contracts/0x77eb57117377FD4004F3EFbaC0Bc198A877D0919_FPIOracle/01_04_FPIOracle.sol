// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "../interfaces/IFPIControllerPool.sol";

contract FPIOracle is AggregatorV3Interface {
    using SafeCast for uint256;

    IFPIControllerPool public immutable fpiControllerPool;
    uint8 public immutable FPI_ORACLE_DECIMALS;

    constructor(address _fpiControllerPoolAddress, uint8 _fpiOracleDecimals) {
        fpiControllerPool = IFPIControllerPool(_fpiControllerPoolAddress);
        FPI_ORACLE_DECIMALS = _fpiOracleDecimals;
    }

    /// @notice The ```decimals``` function represents the number of decimals the aggregator responses represent.
    function decimals() external view returns (uint8) {
        return FPI_ORACLE_DECIMALS;
    }

    /// @notice The ```description``` function retuns the items represented as Item / Units
    function description() external pure returns (string memory) {
        return "FPI / USD";
    }

    function version() external pure returns (uint256) {
        return 1;
    }

    function getRoundData(uint80 _roundId)
        external
        pure
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        revert("No Implementation for getRoundData");
    }

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        roundId = 0;
        startedAt = 0;
        updatedAt = 0;
        answeredInRound = 0;

        answer = fpiControllerPool.getFPIPriceE18().toInt256();
    }
}