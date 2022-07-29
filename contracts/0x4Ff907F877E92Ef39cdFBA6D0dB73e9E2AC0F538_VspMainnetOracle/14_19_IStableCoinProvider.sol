// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IStableCoinProvider {
    /**
     * @notice Return the stable coin if pegged
     * @dev Check price relation between both stable coins and revert if peg is too loose
     * @return _stableCoin The primary stable coin if pass all checks
     */
    function getStableCoinIfPegged() external view returns (address _stableCoin);

    /**
     * @notice Convert given amount of stable coin to USD representation (18 decimals)
     */
    function toUsdRepresentation(uint256 stableCoinAmount_) external view returns (uint256 _usdAmount);
}