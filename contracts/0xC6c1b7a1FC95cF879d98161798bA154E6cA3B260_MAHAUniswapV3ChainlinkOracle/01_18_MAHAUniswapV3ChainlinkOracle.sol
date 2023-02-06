// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {IUniswapV3Factory} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import {IUniswapV3Pool} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import {AggregatorV3Interface} from "../interfaces/AggregatorV3Interface.sol";
import {UniswapPrice} from "../uniswap/UniswapPrice.sol";
import {IGMUOracle} from "../interfaces/IGMUOracle.sol";

contract MAHAUniswapV3ChainlinkOracle is AggregatorV3Interface, UniswapPrice {
    uint256 public ratePerEpoch;
    mapping(address => address) public tokenStakingPool;

    /// @dev the uniswap v3 factory
    IUniswapV3Factory public factory;

    /// @dev the uniswap v3 pool
    IUniswapV3Pool public pool;

    IGMUOracle public gmuOracle;

    address public arth;
    address public maha;
    uint24 public fee;

    constructor(
        address _pool,
        address _gmuOracle,
        address _arth,
        address _maha,
        uint24 _fee
    ) {
        pool = IUniswapV3Pool(_pool);
        factory = IUniswapV3Factory(pool.factory());

        maha = _maha;
        arth = _arth;
        fee = _fee;

        gmuOracle = IGMUOracle(_gmuOracle);
    }

    function fetchPriceInARTH() public view returns (uint256) {
        return getPrice(factory, arth, maha, fee);
    }

    function fetchPrice() public view returns (uint256) {
        return
            (getPrice(factory, arth, maha, fee) *
                gmuOracle.fetchLastGoodPrice()) / 1e18;
    }

    function decimals() external pure override returns (uint8) {
        return 8;
    }

    function description() external pure override returns (string memory) {
        return
            "A chainlink v3 aggregator port for the ARTH GMU oracle. It gives the ARTH price in USD terms.";
    }

    function version() external pure override returns (uint256) {
        return 1;
    }

    function getRoundData(uint80 _roundId)
        external
        view
        override
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        return (
            _roundId,
            int256(fetchPrice() / 1e10),
            0,
            block.timestamp,
            _roundId
        );
    }

    function latestRoundData()
        external
        view
        override
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        return (1, int256(fetchPrice() / 1e10), 0, block.timestamp, 1);
    }

    function latestAnswer() external view override returns (int256) {
        return int256(fetchPrice()) / 1e10;
    }

    function latestTimestamp() external view override returns (uint256) {
        return block.timestamp;
    }

    function latestRound() external view override returns (uint256) {
        return block.timestamp;
    }

    function getAnswer(uint256) external view override returns (int256) {
        return int256(fetchPrice()) / 1e10;
    }

    function getTimestamp(uint256) external view override returns (uint256) {
        return block.timestamp;
    }
}