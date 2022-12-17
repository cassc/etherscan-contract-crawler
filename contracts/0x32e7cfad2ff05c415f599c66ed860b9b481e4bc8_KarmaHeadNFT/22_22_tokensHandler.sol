// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.16;

import "../../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "../../lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

contract TokenHandler {
    address public immutable usdcAddress;
    address public immutable wethAddress;

    using SafeERC20 for IERC20;

    constructor(address _usdcAddress, address _wethAddress) {
        require(_usdcAddress != address(0), "Invalid USDC address");
        require(_wethAddress != address(0), "Invalid WETH address");
        require(_usdcAddress != _wethAddress, "Invalid USDC or WETH addresses");
        usdcAddress = _usdcAddress;
        wethAddress = _wethAddress;
    }

    // @dev     This function is only to recover potential lost ERC20tokens other than USDC and WETH
    function _recoverTokens(address token, address to) internal {
        if (_validToken(token)) revert("This method cannot be used with USDC / WETH");

        uint256 amount = IERC20(token).balanceOf(address(this));
        if (amount == 0) revert("No tokens to recover");

        // safeTransfer to protect from malicious tokens
        IERC20(token).safeTransfer(to, amount);
    }

    function _validToken(address token) internal view returns (bool) {
        return ((token == usdcAddress) || (token == wethAddress));
    }
}