// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.7.6;
pragma abicoder v2;

interface IIchiVaultSettingsV1 {

    function executionDelay() external view returns(uint256);
    function twapSlow() external view returns(uint32);
    function twapFast() external view returns(uint32);
    function extremeVolatility() external view returns(uint256);
    function highVolatility() external view returns(uint256);
    function someVolatility() external view returns(uint256);
    function dtrDelta() external view returns(uint256);
    function priceChange() external view returns(uint256);

    function setExecutionDelay(uint256 _executionDelay) external;
    function setTwapSlow(uint32 _twapSlow) external;
    function setTwapFast(uint32 _twapFast) external;
    function setExtremeVolatility(uint256 _extremeVolatility) external;
    function setHighVolatility(uint256 _highVolatility) external;
    function setSomeVolatility(uint256 _someVolatility) external;
    function setDtrDelta(uint256 _dtrDelta) external;
    function setPriceChange(uint256 _priceChange) external;

    function setAll(
        uint256 _executionDelay,
        uint32 _twapSlow,
        uint32 _twapFast,
        uint256 _extremeVolatility,
        uint256 _highVolatility,
        uint256 _someVolatility,
        uint256 _dtrDelta,
        uint256 _priceChange
    ) external;

    event DeploySettings(
        address indexed sender, 
        uint256 executionDelay,
        uint32 twapSlow,
        uint32 twapFast,
        uint256 extremeVolatility,
        uint256 highVolatility,
        uint256 someVolatility,
        uint256 dtrDelta,
        uint256 priceChange
    );

    event SetAll(
        address indexed sender, 
        uint256 executionDelay,
        uint32 twapSlow,
        uint32 twapFast,
        uint256 extremeVolatility,
        uint256 highVolatility,
        uint256 someVolatility,
        uint256 dtrDelta,
        uint256 priceChange
    );

    event SetExecutionDelay(
        address indexed sender, 
        uint256 executionDelay
    );

    event SetTwapSlow(
        address indexed sender, 
        uint32 twapSlow
    );

    event SetTwapFast(
        address indexed sender, 
        uint32 twapFast
    );

    event SetExtremeVolatility(
        address indexed sender, 
        uint256 extremeVolatility
    );

    event SetHighVolatility(
        address indexed sender, 
        uint256 highVolatility
    );

    event SetSomeVolatility(
        address indexed sender, 
        uint256 someVolatility
    );

    event SetDtrDelta(
        address indexed sender, 
        uint256 dtrDelta
    );

    event SetPriceChange(
        address indexed sender, 
        uint256 priceChange
    );
}