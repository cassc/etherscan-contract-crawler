// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

pragma experimental ABIEncoderV2;

import "./UniswapV2OracleLibrary.sol";
import "./Constants.sol";
import "@openzeppelin/[email protected]/access/Ownable.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";

interface IUSDC {
    function isBlacklisted(address _account) external view returns (bool);
}

contract Oracle is Ownable{
    using Decimal for Decimal.D256;

    address private constant UNISWAP_FACTORY =
        address(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);

    IUniswapV2Pair internal _uniV2Pair;
    address internal _dollar;
    address internal _dao;
    bool internal _initialized;
    uint256 internal _index;
    uint256 internal _cumulative;
    uint32 internal _timestamp;
    uint256 internal _reserve;

    constructor(address dollar) public{
        _dollar = dollar;
        setup();
    }

    function setup() internal {
        _uniV2Pair = IUniswapV2Pair(
            IUniswapV2Factory(UNISWAP_FACTORY).createPair(_dollar, usdc())
        );

        (address token0, address token1) = (
            _uniV2Pair.token0(),
            _uniV2Pair.token1()
        );
        _index = _dollar == token0 ? 0 : 1;

        require(_index == 0 || _dollar == token1, "Dollar not found");
    }

    function setDao(address daoAddress) external onlyOwner{
        _dao = daoAddress;
    }

    /**
     * Trades/Liquidity: (1) Initializes reserve and blockTimestampLast (can calculate a price)
     *                   (2) Has non-zero cumulative prices
     *
     * Steps: (1) Captures a reference blockTimestampLast
     *        (2) First reported value
     */
    function capture()
        public
        returns (Decimal.D256 memory, bool)
    {
        require(msg.sender == _dao, "not dao");
        if (_initialized) {
            return updateOracle();
        } else {
            initializeOracle();
            return (Decimal.one(), false);
        }
    }

    function initializeOracle() internal {
        IUniswapV2Pair pair = _uniV2Pair;
        uint256 priceCumulative = _index == 0
            ? pair.price0CumulativeLast()
            : pair.price1CumulativeLast();
        (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = pair
            .getReserves();
        if (reserve0 != 0 && reserve1 != 0 && blockTimestampLast != 0) {
            _cumulative = priceCumulative;
            _timestamp = blockTimestampLast;
            _initialized = true;
            _reserve = _index == 0 ? reserve1 : reserve0; // get counter's reserve
        }
    }

    function updateOracle() internal returns (Decimal.D256 memory, bool) {
        Decimal.D256 memory price = updatePrice();
        uint256 lastReserve = updateReserve();
        bool isBlacklisted = IUSDC(usdc()).isBlacklisted(address(_uniV2Pair));

        bool valid = true;
        if (lastReserve < Constants.getOracleReserveMinimum()) {
            valid = false;
        }
        if (_reserve < Constants.getOracleReserveMinimum()) {
            valid = false;
        }
        if (isBlacklisted) {
            valid = false;
        }

        return (price, valid);
    }

    function updatePrice() internal returns (Decimal.D256 memory) {
        (
            uint256 price0Cumulative,
            uint256 price1Cumulative,
            uint32 blockTimestamp
        ) = UniswapV2OracleLibrary.currentCumulativePrices(address(_uniV2Pair));
        uint32 timeElapsed = blockTimestamp - _timestamp; // overflow is desired
        uint256 priceCumulative = _index == 0
            ? price0Cumulative
            : price1Cumulative;
        Decimal.D256 memory price = Decimal.ratio(
            (priceCumulative - _cumulative) / timeElapsed,
            2**112
        );

        _timestamp = blockTimestamp;
        _cumulative = priceCumulative;

        return price.mul(1e12);
    }

    function updateReserve() internal returns (uint256) {
        uint256 lastReserve = _reserve;
        (uint112 reserve0, uint112 reserve1, ) = _uniV2Pair.getReserves();
        _reserve = _index == 0 ? reserve1 : reserve0; // get counter's reserve

        return lastReserve;
    }

    function usdc() internal pure returns (address) {
        return Constants.getUsdcAddress();
    }

    function pairAddress() external view returns (address) {
        return address(_uniV2Pair);
    }

    function reserve() external view returns (uint256) {
        return _reserve;
    }
}