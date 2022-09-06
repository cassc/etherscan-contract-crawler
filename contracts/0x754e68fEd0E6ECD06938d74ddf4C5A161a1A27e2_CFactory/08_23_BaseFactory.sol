// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.11;

// Internal references
import { Errors } from "@sense-finance/v1-utils/src/libs/Errors.sol";
import { BaseAdapter } from "../BaseAdapter.sol";
import { Divider } from "../../../Divider.sol";
import { FixedMath } from "../../../external/FixedMath.sol";

interface ChainlinkOracleLike {
    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function decimals() external view returns (uint256 decimals);
}

abstract contract BaseFactory {
    using FixedMath for uint256;

    /* ========== CONSTANTS ========== */

    address public constant ETH_USD_PRICEFEED = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419; // Chainlink ETH-USD price feed

    /// @notice Sets level to `31` by default, which keeps all Divider lifecycle methods public
    /// (`issue`, `combine`, `collect`, etc), but not the `onRedeem` hook.
    uint48 public constant DEFAULT_LEVEL = 31;

    /* ========== PUBLIC IMMUTABLES ========== */

    /// @notice Sense core Divider address
    address public immutable divider;

    /// @notice target -> adapter
    mapping(address => address) public adapters;

    /// @notice params for adapters deployed with this factory
    FactoryParams public factoryParams;

    /* ========== DATA STRUCTURES ========== */

    struct FactoryParams {
        address oracle; // oracle address
        address stake; // token to stake at issuance
        uint256 stakeSize; // amount to stake at issuance
        uint256 minm; // min maturity (seconds after block.timstamp)
        uint256 maxm; // max maturity (seconds after block.timstamp)
        uint128 ifee; // issuance fee
        uint16 mode; // 0 for monthly, 1 for weekly
        uint64 tilt; // tilt
        uint256 guard; // adapter guard (in usd)
    }

    constructor(address _divider, FactoryParams memory _factoryParams) {
        divider = _divider;
        factoryParams = _factoryParams;
    }

    /* ========== REQUIRED DEPLOY ========== */

    /// @notice Deploys both an adapter and a target wrapper for the given _target
    /// @param _target Address of the Target token
    /// @param _data Additional data needed to deploy the adapter
    function deployAdapter(address _target, bytes memory _data) external virtual returns (address adapter) {}

    /// Set adapter's guard to $100`000 in target
    /// @notice if Underlying-ETH price feed returns 0, we set the guard to 100000 target.
    function _setGuard(address adapter) internal {
        // We only want to execute this if divider is guarded
        if (Divider(divider).guarded()) {
            // Get Underlying-ETH price
            try BaseAdapter(adapter).getUnderlyingPrice() returns (uint256 underlyingPriceInEth) {
                // Get ETH-USD price from Chainlink (in 8 decimals base)
                (, int256 ethPrice, , uint256 ethUpdatedAt, ) = ChainlinkOracleLike(ETH_USD_PRICEFEED)
                    .latestRoundData();

                if (block.timestamp - ethUpdatedAt > 2 hours) revert Errors.InvalidPrice();

                // Calculate Underlying-USD price (normalised to 18 deicmals)
                uint256 price = underlyingPriceInEth.fmul(uint256(ethPrice) * 1e10);

                // Calculate Target-USD price
                price = BaseAdapter(adapter).scale().fdiv(price);

                Divider(divider).setGuard(adapter, factoryParams.guard.fdiv(price));
            } catch {}
        }
    }

    /* ========== LOGS ========== */

    /// @notice Logs the deployment of the adapter
    event AdapterAdded(address addr, address indexed target);
}