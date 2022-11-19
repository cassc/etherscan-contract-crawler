// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.4;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorInterface.sol";

interface IGemGlobalConfig {
    function initialize(
        address _finToken,
        address _governor,
        address _definerAdmin,
        address payable _deFinerCommunityFund,
        uint256 _poolCreationFeeInUSD8,
        AggregatorInterface _nativeTokenOracleForPriceInUSD8
    ) external;

    function finToken() external view returns (address);

    function governor() external view returns (address);

    function definerAdmin() external view returns (address);

    function nativeTokenOracleForPriceInUSD8() external view returns (address);

    function deFinerCommunityFund() external view returns (address payable);

    function getPoolCreationFeeInNative() external view returns (uint256);

    function getNativeTokenPriceInUSD8() external view returns (int256);

    function nativeTokenPriceOracleInUSD8() external view returns (address);
}