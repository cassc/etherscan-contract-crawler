pragma solidity 0.8.13;

// SPDX-License-Identifier: MIT

import { SwapVesting, IERC20 } from "./SwapVesting.sol";

contract CBSNVesting is SwapVesting {

    /// @notice Linear unlock schedule params for BSN
    struct BSNSchedule {
        uint256 start;
        uint256 end;
        uint256 amount;
    }

    /// @notice BSN tokens slowly unlock linearly according to this schedule
    BSNSchedule public dripSchedule;

    /// @notice Total BSN allocated to vesting schedules
    uint256 public totalBSNAllocated;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function init(
        address _vestedToken,
        address _contractOwner,
        IERC20 _inputToken,
        address _vestedTokenSource,
        address _inputBurnAddress,
        uint256 _inputToVestedTokenExchangeRate,
        uint256 _waitPeriod,
        uint256 _vestingLength,
        uint256 _bsnDripStart,
        uint256 _bsnDripEnd,
        uint256 _bsnAmount
    ) external initializer {
        // end must be greater than start
        require(_bsnDripEnd > _bsnDripStart, "Invalid end");

        // amount must be non zero
        require(_bsnAmount > 0, "Invalid amount");

        dripSchedule = BSNSchedule({
            start: _bsnDripStart,
            end: _bsnDripEnd,
            amount: _bsnAmount
        });

        __Swap_Vesting_init(
            _vestedToken,
            _contractOwner,
            _inputToken,
            _vestedTokenSource,
            _inputBurnAddress,
            _inputToVestedTokenExchangeRate,
            _waitPeriod,
            _vestingLength
        );
    }

    /// @notice Total amount of cBSN that can be exchanged for BSN by any account. This unlocks linearly on a fixed schedule
    function BSNAvailableForClaim() public view returns (uint256) {
        uint256 availableOutput = _availableDrawDownAmount(
            dripSchedule.start,
            dripSchedule.end,
            dripSchedule.start,
            dripSchedule.amount,
            address(this)
        );

        return availableOutput - totalBSNAllocated;
    }

    /// @dev Available output is based on BSN unlocking linearly
    function _isOutputAmountAvailable(uint256 _outputAmount) internal override view returns (bool) {
        if (_outputAmount == 0) {
            return false;
        }

        return BSNAvailableForClaim() >= _outputAmount;
    }

    /// @dev Increases total BSN allocated due to a new vesting schedule
    function _reserveOutputAmount(uint256 _outputAmount) internal override {
        require(totalBSNAllocated + _outputAmount <= dripSchedule.amount, "Bad reserve");
        totalBSNAllocated += _outputAmount;
    }
}