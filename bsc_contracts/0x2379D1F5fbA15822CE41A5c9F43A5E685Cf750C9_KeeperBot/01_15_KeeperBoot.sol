// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";
import "@chainlink/contracts/src/v0.8/AutomationBase.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV2V3Interface.sol";
import "./interfaces/IUniswapV2Pair.sol";
import "./interfaces/IFlashBot.sol";

contract KeeperBot is AutomationCompatibleInterface, AutomationBase, Ownable {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using EnumerableSet for EnumerableSet.AddressSet;

    IFlashBot private immutable flashBot;

    address private immutable keeperRegistery; //Keeper registry contract.

    uint256 public constant PRICE_PRECISION = 10**18;
    uint256 public constant ONE_USD = PRICE_PRECISION;
    uint256 public minProfit;

    struct Pool {
        address pool0;
        address pool1;
    }

    struct PriceFeed {
        address aggregator;
        uint8 decimals;
    }

    mapping(bytes32 => Pool) private pools;
    EnumerableSet.Bytes32Set private poolsIndex;
    mapping(address => PriceFeed) private pricesTokens;
    EnumerableSet.AddressSet private stableTokens;

    constructor(address _keeperRegistery, address _flashBot) {
        keeperRegistery = _keeperRegistery;
        flashBot = IFlashBot(_flashBot);
        minProfit = 0.05 ether;
    }

    modifier onlyKeeper() {
        require(_msgSender() == keeperRegistery, "Only Keeper Registry");
        _;
    }

    function _numDigits(uint256 number) private pure returns (uint256) {
        uint256 digits = 0;
        while (number != 0) {
            number /= 10;
            digits++;
        }
        return digits;
    }

    function _getPagination()
        private
        view
        returns (uint256 book_, uint256 digitpage_)
    {
        uint256 _book = totalPools().div(100);
        uint256 remainder = _book.mul(100);
        _book = remainder < totalPools() ? _book.add(1) : _book;
        return (_book, _numDigits(_book));
    }

    function _calcProfit(uint256 profit, address baseToken)
        private
        view
        returns (uint256)
    {
        uint256 price = getPrice(baseToken);
        if (price == 0) return 0;
        uint256 tokenDecimals = IERC20Metadata(baseToken).decimals();
        profit = profit.mul(PRICE_PRECISION).div(10**tokenDecimals);
        return profit.mul(price).div(PRICE_PRECISION);
    }

    function getBatch() public view returns (uint256 start, uint256 end) {
        if (totalPools() != 0) {
            (uint256 pages, uint256 batchDigits) = _getPagination();
            uint256 index = block.number % (10**batchDigits);
            index = index == 0 ? 1 : index;
            while (index > pages) {
                index -= pages;
            }
            uint256 start_ = index.sub(1).mul(100);
            uint256 end_ = index.mul(100) > totalPools()
                ? totalPools()
                : index.mul(100);
            return (start_, end_);
        }
        return (0, 0);
    }

    function totalPools() public view returns (uint256) {
        return poolsIndex.length();
    }

    function getPoolAt(uint256 index) external view returns (bytes32) {
        return poolsIndex.at(index);
    }

    function getPool(bytes32 poolId) external view returns (Pool memory) {
        require(poolsIndex.contains(poolId), "Query for nonexistent pool");
        return pools[poolId];
    }

    function getPrice(address _token) public view returns (uint256) {
        if (stableTokens.contains(_token)) {
            return ONE_USD;
        }
        PriceFeed storage pFeed = pricesTokens[_token];
        address priceFeedAddress = pFeed.aggregator;
        if (priceFeedAddress == address(0)) {
            return 0;
        }

        AggregatorV2V3Interface _priceFeed = AggregatorV2V3Interface(
            priceFeedAddress
        );

        int256 price = _priceFeed.latestAnswer();
        if (price == 0) {
            return 0;
        }
        // normalise price precision
        uint256 priceDecimals = pFeed.decimals;
        return uint256(price).mul(PRICE_PRECISION).div(10**priceDecimals);
    }

    function checkUpkeep(bytes calldata checkData)
        external
        view
        override
        cannotExecute
        returns (bool, bytes memory)
    {
        (uint256 start, uint256 end) = getBatch();
        for (uint256 i = start; i < end; i++) {
            bytes32 poolId = poolsIndex.at(i);
            Pool memory pool = pools[poolId];
            (uint256 profit, address baseToken) = flashBot.getProfit(
                pool.pool0,
                pool.pool1
            );
            uint256 netProfit = _calcProfit(profit, baseToken);
            if (netProfit >= minProfit) {
                return (true, abi.encodePacked(poolId));
            }
        }
        return (false, checkData);
    }

    /**
     * @notice Execute an order, only keepers can do this execution.
     * @param performData order id to execute.
     */
    function performUpkeep(bytes calldata performData)
        external
        override
        onlyKeeper
    {
        bytes32 poolId = abi.decode(performData, (bytes32));
        Pool memory pool = pools[poolId];
        flashBot.flashArbitrage(pool.pool0, pool.pool1);
    }

    function setMinProfit(uint256 _profit) external onlyOwner {
        require(_profit >= 0.01 ether);
        minProfit = _profit;
    }

    function setStableToken(address _token, bool _set) external onlyOwner {
        require(_token != address(0));
        if (_set) {
            stableTokens.add(_token);
        } else {
            stableTokens.remove(_token);
        }
    }

    function setPricesToken(
        address _token,
        address _aggregator,
        bool _set
    ) external onlyOwner {
        require(_token != address(0) && _aggregator != address(0));
        if (_set) {
            uint8 decimals = AggregatorV2V3Interface(_aggregator).decimals();
            require(decimals != 0);
            pricesTokens[_token].aggregator = _aggregator;
            pricesTokens[_token].decimals = decimals;
        } else {
            delete pricesTokens[_token];
        }
    }

    function addPool(address _pool0, address _pool1) external onlyOwner {
        require(_pool0 != _pool1, "Same pair address");
        (address pool0Token0, address pool0Token1) = (
            IUniswapV2Pair(_pool0).token0(),
            IUniswapV2Pair(_pool0).token1()
        );
        (address pool1Token0, address pool1Token1) = (
            IUniswapV2Pair(_pool1).token0(),
            IUniswapV2Pair(_pool1).token1()
        );
        require(
            pool0Token0 < pool0Token1 && pool1Token0 < pool1Token1,
            "Non standard uniswap AMM pair"
        );
        require(
            pool0Token0 == pool1Token0 && pool0Token1 == pool1Token1,
            "Require same token pair"
        );
        require(
            getPrice(pool0Token0) != 0 || getPrice(pool0Token1) != 0,
            "No base token in pair"
        );
        bytes32 poolId = keccak256(abi.encodePacked(_pool0, _pool1));
        require(!poolsIndex.contains(poolId), "Pool exists");
        poolsIndex.add(poolId);
        pools[poolId] = Pool(_pool0, _pool1);
    }

    function removePool(bytes32 poolId) external onlyOwner {
        require(poolsIndex.contains(poolId), "Pool not exists");
        poolsIndex.remove(poolId);
        delete pools[poolId];
    }
}