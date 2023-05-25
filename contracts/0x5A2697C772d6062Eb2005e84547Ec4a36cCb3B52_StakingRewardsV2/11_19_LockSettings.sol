//SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract LockSettings is Ownable {
    /// @dev decimals for: baseRate, APY, multipliers
    ///         eg for baseRate: 1e6 is 1%, 50e6 is 50%
    ///         eg for multipliers: 1e6 is 1.0x, 3210000 is 3.21x
    uint256 public constant RATE_DECIMALS = 10 ** 6;
    uint256 public constant MAX_MULTIPLIER = 5 * RATE_DECIMALS;

    /// @notice token => period => multiplier
    mapping(address => mapping(uint256 => uint256)) public multipliers;

    /// @notice token => period => index in periods array
    mapping(address => mapping(uint256 => uint256)) public periodIndexes;

    /// @notice token => periods
    mapping(address => uint256[]) public periods;

    event TokenSettings(address indexed token, uint256 period, uint256 multiplier);

    function removePeriods(address _token, uint256[] calldata _periods) external onlyOwner {
        for (uint256 i; i < _periods.length; i++) {
            if (_periods[i] == 0) revert("InvalidSettings");

            multipliers[_token][_periods[i]] = 0;
            _removePeriod(_token, _periods[i]);

            emit TokenSettings(_token, _periods[i], 0);
        }
    }

    // solhint-disable-next-line code-complexity
    function setLockingTokenSettings(address _token, uint256[] calldata _periods, uint256[] calldata _multipliers)
        external
        onlyOwner
    {
        if (_periods.length == 0) revert("EmptyPeriods");
        if (_periods.length != _multipliers.length) revert("ArraysNotMatch");

        for (uint256 i; i < _periods.length; i++) {
            if (_periods[i] == 0) revert("InvalidSettings");
            if (_multipliers[i] < RATE_DECIMALS) revert("multiplier must be >= 1e6");
            if (_multipliers[i] > MAX_MULTIPLIER) revert("multiplier overflow");

            multipliers[_token][_periods[i]] = _multipliers[i];
            emit TokenSettings(_token, _periods[i], _multipliers[i]);

            if (_multipliers[i] == 0) _removePeriod(_token, _periods[i]);
            else _addPeriod(_token, _periods[i]);
        }
    }

    function periodsCount(address _token) external view returns (uint256) {
        return periods[_token].length;
    }

    function getPeriods(address _token) external view returns (uint256[] memory) {
        return periods[_token];
    }

    function _addPeriod(address _token, uint256 _period) internal {
        uint256 key = periodIndexes[_token][_period];
        if (key != 0) return;

        periods[_token].push(_period);
        // periodIndexes are starting from 1, not from 0
        periodIndexes[_token][_period] = periods[_token].length;
    }

    function _removePeriod(address _token, uint256 _period) internal {
        uint256 key = periodIndexes[_token][_period];
        if (key == 0) return;

        periods[_token][key - 1] = periods[_token][periods[_token].length - 1];
        periodIndexes[_token][_period] = 0;
        periods[_token].pop();
    }
}