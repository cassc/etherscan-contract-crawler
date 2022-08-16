// SPDX-License-Identifier: Apache-2.0

pragma solidity =0.8.9;

import "../interfaces/IERC20Minimal.sol";
import "../interfaces/fcms/IFCM.sol";
import "../interfaces/IMarginEngine.sol";
import "../interfaces/IVAMM.sol";

contract MarginEngineStorageV1 {
    // Any variables that would implicitly implement an IMarginEngine function if public, must instead
    // be internal due to limitations in the solidity compiler (as of 0.8.12)
    uint256 internal _liquidatorRewardWad;
    IERC20Minimal internal _underlyingToken;
    uint256 internal _termStartTimestampWad;
    uint256 internal _termEndTimestampWad;
    IFCM internal _fcm;
    mapping(bytes32 => Position.Info) internal positions;
    IVAMM internal _vamm;
    uint256 internal _secondsAgo;
    uint256 internal cachedHistoricalApyWad;
    uint256 internal cachedHistoricalApyWadRefreshTimestamp;
    uint256 internal _cacheMaxAgeInSeconds;
    IFactory internal _factory;
    IRateOracle internal _rateOracle;
    IMarginEngine.MarginCalculatorParameters
        internal marginCalculatorParameters;
    bool internal _isAlpha;
    bool public paused;
}

contract MarginEngineStorage is MarginEngineStorageV1 {
    // Reserve some storage for use in future versions, without creating conflicts
    // with other inheritted contracts
    uint256[69] private __gap; // total storage = 100 slots, including structs
}