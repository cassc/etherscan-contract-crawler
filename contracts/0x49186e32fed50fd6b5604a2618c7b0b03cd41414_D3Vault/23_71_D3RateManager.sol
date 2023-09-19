// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../../lib/DecimalMath.sol";
import "../../intf/ID3Vault.sol";
/// @title RateManager
/// @notice  This contract is responsible for calculating the borrowing interest rate.
contract D3RateManager is Ownable {
    using DecimalMath for uint256;

    struct RateStrategy {
        uint256 baseRate; // 1e18 = 100%
        uint256 slope1; // 1e18 = 100%;
        uint256 slope2; // 1e18 = 100%;
        uint256 optimalUsage; // 1e18 = 100%
    }

    mapping(address => RateStrategy) public rateStrategyMap; // token => RateStrategy
    mapping(address => uint256) public tokenTypeMap; // 1: stable; 2: volatile

    /// @notice  Set stable interest rate curve parameters. 
    /// @param token Token address
    /// @param baseRate Initial interest rate.
    /// @param slope1 Initial segment interest rate.
    /// @param slope2 Second segment interest rate.
    /// @param optimalUsage Boundary between the first segment interest rate and the second segment interest rate.
    function setStableCurve(
        address token,
        uint256 baseRate,
        uint256 slope1,
        uint256 slope2,
        uint256 optimalUsage
    ) external onlyOwner {
        rateStrategyMap[token] = RateStrategy(baseRate, slope1, slope2, optimalUsage);
        tokenTypeMap[token] = 1;
    }

    /// @notice  Set volatile interest rate curve parameters. 
    /// @param token Token address
    /// @param baseRate Initial interest rate.
    /// @param slope1 Initial segment interest rate.
    /// @param slope2 Second segment interest rate.
    /// @param optimalUsage Boundary between the first segment interest rate and the second segment interest rate.
    function setVolatileCurve(
        address token,
        uint256 baseRate,
        uint256 slope1,
        uint256 slope2,
        uint256 optimalUsage
    ) external onlyOwner {
        rateStrategyMap[token] = RateStrategy(baseRate, slope1, slope2, optimalUsage);
        tokenTypeMap[token] = 2;
    }

    /// @notice  Set token new type 
    function setTokenType(address token, uint256 tokenType) external onlyOwner {
        tokenTypeMap[token] = tokenType;
    }
    /// @notice  Get the borrowing interest rate for the token.
    /// @param token Token address
    /// @param utilizationRatio Token utilization rate.
    function getBorrowRate(address token, uint256 utilizationRatio) public view returns (uint256 rate) {
        RateStrategy memory s = rateStrategyMap[token];
        if (utilizationRatio <= s.optimalUsage) {
            rate = s.baseRate + utilizationRatio.mul(s.slope1);
        } else {
            rate = s.baseRate + s.optimalUsage.mul(s.slope1) + (utilizationRatio - s.optimalUsage).mul(s.slope2);
        }
    }
}