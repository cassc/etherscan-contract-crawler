pragma solidity 0.8.13;

// SPDX-License-Identifier: MIT

import { SwapVesting, IERC20 } from "./SwapVesting.sol";

contract SHBVesting is SwapVesting {

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    /// @param _vestedToken BSN token address
    /// @param _inputToken SHB token address
    /// @param _inputToVestedTokenExchangeRate SHB to BSN exchange rate
    function init(
        address _vestedToken,
        address _contractOwner,
        IERC20 _inputToken,
        address _vestedTokenSource,
        address _inputBurnAddress,
        uint256 _inputToVestedTokenExchangeRate,
        uint256 _waitPeriod,
        uint256 _vestingLength
    ) external initializer {
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

    /// @dev As SHB to output is a deterministic calc, the contract is always assumed to have output
    function _isOutputAmountAvailable(uint256 _outputAmount) internal override pure returns (bool) {
        if (_outputAmount == 0) {
            return false;
        }

        return true;
    }

    /// @dev As SHB to output is a deterministic calc, the contract does not need to reserve
    function _reserveOutputAmount(uint256) internal override { }
}