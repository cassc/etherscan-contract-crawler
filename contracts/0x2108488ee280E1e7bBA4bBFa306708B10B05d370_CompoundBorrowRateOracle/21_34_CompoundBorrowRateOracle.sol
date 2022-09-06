// SPDX-License-Identifier: Apache-2.0

pragma solidity =0.8.9;

import "../interfaces/rate_oracles/ICompoundRateOracle.sol";
import "../interfaces/compound/ICToken.sol";
import "./BaseRateOracle.sol";
import "../utils/ExponentialNoError.sol";

contract CompoundBorrowRateOracle is
    BaseRateOracle,
    ICompoundRateOracle,
    ExponentialNoError
{
    /// @inheritdoc ICompoundRateOracle
    ICToken public immutable override ctoken;

    /// @inheritdoc ICompoundRateOracle
    uint8 public immutable override decimals;

    uint8 public constant override UNDERLYING_YIELD_BEARING_PROTOCOL_ID = 6; // id of compound is 6

    // Maximum borrow rate that can ever be applied (.0005% / block)
    // https://github.com/compound-finance/compound-protocol/blob/a3214f67b73310d547e00fc578e8355911c9d376/contracts/CTokenInterfaces.sol#L31
    uint256 internal constant BORROW_RATE_MAX_MANTISSA = 0.0005e16;

    constructor(
        ICToken _ctoken,
        bool ethPool,
        IERC20Minimal underlying,
        uint8 _decimals,
        uint32[] memory _times,
        uint256[] memory _results
    ) BaseRateOracle(underlying) {
        ctoken = _ctoken;
        require(
            ethPool || ctoken.underlying() == address(underlying),
            "Tokens do not match"
        );
        // Check that underlying was set in BaseRateOracle
        require(address(underlying) != address(0), "underlying must exist");
        decimals = _decimals;

        _populateInitialObservations(_times, _results);
    }

    /// @inheritdoc BaseRateOracle
    // Follows the accrueInterest() logic from Compound's CToken to compute latest rate
    // https://github.com/compound-finance/compound-protocol/blob/a3214f67b73310d547e00fc578e8355911c9d376/contracts/CToken.sol#L327
    function getLastUpdatedRate()
        public
        view
        override
        returns (uint32 timestamp, uint256 resultRay)
    {
        uint256 borrowRateMantissa = ctoken.borrowRatePerBlock();
        require(
            borrowRateMantissa <= BORROW_RATE_MAX_MANTISSA,
            "borrow rate is absurdly high"
        );

        uint256 blockDelta = block.number - ctoken.accrualBlockNumber();
        // rate accrued since last index update
        Exp memory simpleInterestFactor = mul_(
            Exp({mantissa: borrowRateMantissa}),
            blockDelta
        );

        uint256 borrowIndexPrior = ctoken.borrowIndex();
        uint256 borrowIndex = mul_ScalarTruncateAddUInt(
            simpleInterestFactor,
            borrowIndexPrior,
            borrowIndexPrior
        ); // result given in wad, scale to ray

        return (Time.blockTimestampTruncated(), borrowIndex * 1e9);
    }
}