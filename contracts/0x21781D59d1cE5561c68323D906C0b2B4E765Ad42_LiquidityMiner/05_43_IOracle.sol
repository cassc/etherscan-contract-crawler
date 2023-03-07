// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface for Oracle.sol contract
 */
interface IOracle {
    function getCost(
        uint256 _amount,
        address _chainlinkFeed,
        address _xftPool
    ) external view returns (uint256);

    function getCostSimpleShift(
        uint256 _amount,
        address _chainlinkFeed,
        address _xftPool,
        address _tokenPool
    ) external view returns (uint256);

    function getTokensForAmount(
        address _pool,
        uint32 _interval,
        address _chainlinkFeed,
        uint256 _amount,
        bool _ethLeftSide,
        address _weth9
    ) external view returns (uint256);

    function ethLeftSide(address _chainlinkFeed) external view returns (bool);

    function getTokensRaw(
        address _xftPool,
        address _tokenPool,
        uint32 _interval,
        uint256 _amount,
        address _weth9
    ) external view returns (uint256);

    function isTokenBelowThreshold(
        uint256 _threshold,
        address _pool,
        uint32 _interval,
        address _chainlinkFeed,
        bool _ethLeftSide,
        address _weth9
    ) external view returns (bool);
}