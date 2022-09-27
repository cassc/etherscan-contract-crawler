// SPDX-License-Identifier: Apache-2.0

pragma solidity =0.8.9;
import "../interfaces/IVAMM.sol";
import "../interfaces/IFactory.sol";
import "../interfaces/IMarginEngine.sol";
import "../core_libraries/Tick.sol";

contract VAMMStorageV1 {
    // cached rateOracle from the MarginEngine associated with the VAMM
    IRateOracle internal rateOracle;
    // cached termStartTimstampWad from the MarginEngine associated with the VAMM
    uint256 internal termStartTimestampWad;
    // cached termEndTimestampWad from the MarginEngine associated with the VAMM
    uint256 internal termEndTimestampWad;
    IMarginEngine internal _marginEngine;
    uint128 internal _maxLiquidityPerTick;
    IFactory internal _factory;

    // Any variables that would implicitly implement an IVAMM function if public, must instead
    // be internal due to limitations in the solidity compiler (as of 0.8.12)
    uint256 internal _feeWad;
    // Mutex
    bool internal _unlocked;
    uint128 internal _liquidity;
    uint256 internal _feeGrowthGlobalX128;
    uint256 internal _protocolFees;
    int256 internal _fixedTokenGrowthGlobalX128;
    int256 internal _variableTokenGrowthGlobalX128;
    int24 internal _tickSpacing;
    mapping(int24 => Tick.Info) internal _ticks;
    mapping(int16 => uint256) internal _tickBitmap;
    IVAMM.VAMMVars internal _vammVars;
    bool internal _isAlpha;

    mapping(address => bool) internal pauser;
    bool public paused;
}

contract VAMMStorage is VAMMStorageV1 {
    // Reserve some storage for use in future versions, without creating conflicts
    // with other inheritted contracts
    uint256[50] private __gap;
}