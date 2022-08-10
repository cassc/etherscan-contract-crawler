// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.6;
pragma abicoder v2;

import "@balancer-labs/v2-pool-utils/contracts/interfaces/IPriceOracle.sol";
import "@balancer-labs/v2-pool-utils/contracts/interfaces/IPoolPriceOracle.sol";
import "@balancer-labs/v2-vault/contracts/interfaces/IVault.sol";
import "@balancer-labs/v2-vault/contracts/PoolRegistry.sol";

import "../../utils/TwoStepOwnable.sol";
import "../PriceProvider.sol";
import "../IERC20Like.sol";

/// @title BalancerV2PriceProvider
/// @notice Price provider contract that reads prices from BalancerV2
contract BalancerV2PriceProvider is PriceProvider, TwoStepOwnable {
    /// @notice Pool data for asset
    /// @param poolId balancer ID for a pool
    /// @param priceOracle address of the pool
    /// @param token0isAsset tell us if token0 in pool is equal asset, if not, then the token1 is asset
    /// this is an optimization, we can save 20% gas by caching this info
    struct BalancerPool {
        bytes32 poolId;
        address priceOracle;
        bool token0isAsset;
    }

    /// @param secondsAgo Each query computes the average over a window of duration `secs` seconds that ended `ago`
    /// seconds ago.
    /// @param periodForAvgPrice Each query computes the average over a window of duration `secs` seconds that ended
    /// `ago` seconds ago. For example, the average over the past 30 minutes is computed by settings secs to 1800 and
    /// ago to 0. If secs is 1800 and ago is 1800 as well, the average between 60 and 30 minutes ago is computed
    /// instead.
    struct State {
        uint32 secondsAgo;
        uint32 periodForAvgPrice; 
    }

    /// @dev this is basically `PriceProvider.quoteToken.decimals()`
    uint256 private immutable _QUOTE_TOKEN_DECIMALS; // solhint-disable-line var-name-mixedcase

    /// @dev The buffer that stores price samples has a size of 1024, so 1023 is the last index
    uint256 private constant _LAST_BUFFER_INDEX = 1024 - 1;

    /// @dev Main BalancerV2 contract, something like router for Uniswap but much more
    IVault public immutable vault;

    State private _state;

    /// @notice Maps asset address to BalancerPool struct
    mapping(address => BalancerPool) public assetsPools;

    /// @notice Emitted when TWAP period changes
    /// @param period new period in seconds, ie. 1800 means 30 min
    event NewPeriod(uint32 period);
    /// @notice Emitted when seconds ago changes
    /// @param ago new seconds ago value in seconds, ie. 1800 means 30 min
    event NewSecondsAgo(uint32 ago);
    /// @notice Emitted when BalancerV2 pool is set for asset
    /// @param asset asset address
    /// @param poolId BalancerV2 pool ID
    event PoolForAsset(address indexed asset, bytes32 indexed poolId);

    /// @param _priceProvidersRepository address of PriceProvidersRepository
    /// @param _vault main BalancerV2 contract, something like router for Uniswap but much more
    /// @param _periodForAvgPrice period in seconds for TWAP price, ie. 1800 means 30 min
    constructor(
        IPriceProvidersRepository _priceProvidersRepository,
        IVault _vault,
        uint32 _periodForAvgPrice
    ) PriceProvider(_priceProvidersRepository) {
        // Ping for _priceProvidersRepository is not needed here, because PriceProvider does it
        if (address(_vault.getProtocolFeesCollector()) == address(0)) revert("InvalidVault");
        vault = _vault;
        _setPeriodForAvgPrice(_periodForAvgPrice);
        _QUOTE_TOKEN_DECIMALS = IERC20Like(_priceProvidersRepository.quoteToken()).decimals();
    }

    /// @dev Setup pool for asset. Use it also for update.
    /// @param _asset asset address
    /// @param _poolId BalancerV2 pool ID
    function setupAsset(address _asset, bytes32 _poolId) external onlyManager {
        IERC20[] memory tokens = verifyPool(_poolId, _asset);

        assetsPools[_asset] = BalancerPool(_poolId, resolvePoolAddress(_poolId), address(tokens[0]) == _asset);

        emit PoolForAsset(_asset, _poolId);

        // make sure getPrice does not revert
        getPrice(_asset);
    }

    /// @notice Change period for average price
    /// @param _period period in seconds for TWAP price, ie. 1800 means 30 min
    function changePeriodForAvgPrice(uint32 _period) external onlyManager {
        _setPeriodForAvgPrice(_period);
    }

    /// @notice Change number of seconds in the past when calculations start for average price
    /// @param _ago new seconds ago value in seconds, ie. 1800 means 30 min
    function changeSecondsAgo(uint32 _ago) external onlyManager {
        _setSecondsAgo(_ago);
    }

    /// @notice Change period for average price and number of seconds in the past when calculations start
    /// for average price
    /// @param _period period in seconds for TWAP price, ie. 1800 means 30 min
    /// @param _ago new seconds ago value in seconds, ie. 1800 means 30 min
    function changeSettings(uint32 _period, uint32 _ago) external onlyManager {
        _setPeriodForAvgPrice(_period);
        _setSecondsAgo(_ago);
    }

    /// @inheritdoc IPriceProvider
    function assetSupported(address _asset) external view override returns (bool) {
        return assetsPools[_asset].priceOracle != address(0) || _asset == quoteToken;
    }

    /// @notice Checks if price buffer is ready for a BalancerV2 pool assigned to an asset
    /// @param _asset asset address
    /// @return true if buffer ready, otherwise false
    function priceBufferReady(address _asset) external view returns (bool) {
        bytes32 poolId = assetsPools[_asset].poolId;
        
        if (poolId == bytes32(0)) {
            return false;
        }

        (,,,,,, uint256 timestamp) = IPoolPriceOracle(resolvePoolAddress(poolId)).getSample(_LAST_BUFFER_INDEX);
        return timestamp != 0;
    }

    /// @notice Information for a Time Weighted Average query.
    function secondsAgo() external view returns (uint32) {
        return _state.secondsAgo;
    }

    /// @notice Information for a Time Weighted Average query.
    function periodForAvgPrice() external view returns (uint32) {
        return _state.periodForAvgPrice;
    }
    
    /// @notice Returns price for a given asset
    /// @dev Balancer docs:
    ///     | Some pools (WeightedPool2Tokens and MetaStable Pools) have optional Oracle functionality.
    ///     | This means that they can be used as sources of on-chain price data.
    ///
    ///     | Note from balancer docs: that you can only call getWeightedTimeAverage after the buffer is full,
    ///     | or it will revert with ORACLE_NOT_INITIALIZED. If you call getSample(1023) and it returns 0's,
    ///     | that means the buffer's not full yet.
    ///
    /// We are using Resilient way (recommended by balancer for lending protocols),
    /// Less up-to-date but more resilient to manipulation
    /// @param _asset asset address
    /// @return price of asset in 18 decimals
    function getPrice(address _asset) public view override returns (uint256 price) {
        if (_asset == quoteToken) {
            return 10 ** _QUOTE_TOKEN_DECIMALS;
        }

        BalancerPool storage pool = assetsPools[_asset];
        address priceOracle = pool.priceOracle;
        if (priceOracle == address(0)) revert("PoolNotSet");

        State memory state = _state;
        IPriceOracle.OracleAverageQuery[] memory queries = new IPriceOracle.OracleAverageQuery[](1);
        queries[0] = IPriceOracle.OracleAverageQuery(
            IPriceOracle.Variable.PAIR_PRICE,
            state.periodForAvgPrice,
            state.secondsAgo
        );

        // `getTimeWeightedAverage` uses `getPastAccumulator`, that method returns the value of the accumulator
        // for `variable` `ago` seconds ago.
        //
        // Reverts under the following conditions:
        // - if the buffer is empty.
        // - if querying past information and the buffer has not been fully initialized.
        // - if querying older information than available in the buffer. Note that a full buffer guarantees queries
        //   for the past 34 hours will not revert.
        //
        // If requesting information for a timestamp later than the latest one, it is extrapolated using the latest
        // available data.
        //
        // When no exact information is available for the requested past timestamp (as usually happens,
        // since at most one timestamp is stored every two minutes), it is estimated by performing linear interpolation
        // using the closest values. This process is guaranteed to complete performing at most 10 storage reads.
        //
        // We have also option to use priceOracle.getLargestSafeQueryWindow() but it will not allow for custom period.
        uint256[] memory results = IPriceOracle(priceOracle).getTimeWeightedAverage(queries);

        price = pool.token0isAsset ? 1e36 / results[0] : results[0];
    }

    /// @notice Checks if provided `_poolId` is valid pool for `_asset`
    /// @dev NOTICE: keep in ming anyone can register pool in balancer Vault
    /// https://github.com/balancer-labs/balancer-v2-monorepo
    /// /blob/09c69ed5dc4715a0076c1dc87a81c0b6c2669b5a/pkg/vault/contracts/PoolRegistry.sol#L67
    /// Only some pools (WeightedPool2Tokens and MetaStable Pools) provides oracle functionality.
    /// To be 100% sure, if pool has build-in oracle, we need to do call for getLargestSafeQueryWindow()
    /// and see if it fails or not.
    /// @param _poolId balancer poolId
    /// @param _asset token address for which we want to check the pool
    /// @return tokens IERC20[] pool tokens in original order, vault throws `INVALID_POOL_ID` error when pool is invalid
    function verifyPool(bytes32 _poolId, address _asset) public view returns (IERC20[] memory tokens) {
        if (_asset == address(0)) revert("AssetIsZero");
        if (_poolId == bytes32(0)) revert("PoolIdIsZero");

        address quote = quoteToken;

        uint256[] memory balances;
        (tokens, balances,) = vault.getPoolTokens(_poolId);

        (address tokenAsset, address tokenQuote) = address(tokens[0]) == quote
            ? (address(tokens[1]), address(tokens[0]))
            : (address(tokens[0]), address(tokens[1]));

        if (tokenAsset != _asset) revert("InvalidPoolForAsset");

        if (tokenQuote != quote) revert("InvalidPoolForQuoteToken");

        uint256 quoteBalance = address(tokens[0]) == quote ? balances[0] : balances[1];
        if (quoteBalance == 0) revert("EmptyPool");

        address pool = resolvePoolAddress(_poolId);

        (bool success, bytes memory data) = pool.staticcall(
            abi.encodePacked(IPriceOracle.getLargestSafeQueryWindow.selector)
        );

        if (!success || data.length == 0) revert("InvalidPool");
    }

    /// @notice Gets amount of quote token deposited in the pool
    /// @param _poolId must be valid pool for asset, balancer will throw BAL#500 if it's not
    /// @return amount of quote token in the pool, vault throws `INVALID_POOL_ID` error when pool is invalid
    function getPoolQuoteLiquidity(bytes32 _poolId) public view returns (uint256) {
        if (_poolId == bytes32(0)) {
            return 0;
        }

        (
            IERC20[] memory tokens,
            uint256[] memory balances,
            // uint256 lastChangeBlock
        ) = vault.getPoolTokens(_poolId);

        return address(tokens[0]) == quoteToken ? balances[0] : balances[1];
    }

    /// @notice Returns the address of a Pool's contract.
    /// This is exact copy from Balancer repo.
    /// @dev Due to how Pool IDs are created, this is done with no storage accesses and costs little gas.
    /// @param _poolId valid pool for asset
    /// @return pool address
    function resolvePoolAddress(bytes32 _poolId) public pure returns (address) {
        // 12 byte logical shift left to remove the nonce and specialization setting. We don't need to mask,
        // since the logical shift already sets the upper bits to zero.
        return address(uint256(_poolId) >> (12 * 8));
    }


    /// @dev Sets period for average price
    /// @param _period period in seconds for TWAP price, ie. 1800 means 30 min
    function _setPeriodForAvgPrice(uint32 _period) internal {
        if (_period == 0) revert("InvalidPeriodForAvgPrice");
        if (_state.periodForAvgPrice == _period) revert("PeriodForAvgPriceDidNotChange");

        _state.periodForAvgPrice = _period;
        emit NewPeriod(_period);
    }

    /// @dev Sets number of seconds in the past when calculations start for average price
    /// @param _ago new seconds ago value in seconds, ie. 1800 means 30 min
    function _setSecondsAgo(uint32 _ago) internal {
        if (_state.secondsAgo == _ago) revert("SecondsAgoDidNotChange");

        _state.secondsAgo = _ago;
        emit NewSecondsAgo(_ago);
    }
}