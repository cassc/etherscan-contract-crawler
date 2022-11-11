// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.14;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @notice Helpers for swapping tokens
library ExchangeHelpers {
    using SafeERC20 for IERC20;

    /// @dev Perform a swap between two tokens
    /// @param _sellToken Token to exchange
    /// @param _swapTarget The address of the contract that swaps tokens
    /// @param _swapCallData Call data provided by 0x to fill the quote
    /// @return True if the call succeeded, false if not
    function fillQuote(
        IERC20 _sellToken,
        address _swapTarget,
        bytes memory _swapCallData
    ) internal returns (bool) {
        setMaxAllowance(_sellToken, _swapTarget);
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = _swapTarget.call(_swapCallData);
        return success;
    }

    /// @dev sets the allowance for a token to the maximum if it is not already at max
    /// @param _token The token to use for the allowance setting
    /// @param _spender Spender to allow
    function setMaxAllowance(IERC20 _token, address _spender) internal {
        uint256 _currentAllowance = _token.allowance(address(this), _spender);
        if (_currentAllowance != type(uint256).max) {
            // Decrease to 0 first for tokens mitigating the race condition
            _token.safeDecreaseAllowance(_spender, _currentAllowance);
            _token.safeIncreaseAllowance(_spender, type(uint256).max);
        }
    }
}