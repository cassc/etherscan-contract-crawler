// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

contract Recoverable {
    using SafeERC20 for IERC20;

    address private _ZERO_ADDRESS = address(0);

    /**
     * @dev Can use the below function by adding restrictions
     * such as `onlyOwner` in the child contract.
     * ```
     * function recoverFunds(
     *     address _token,
     *     address _to,
     *     uint256 _amount
     * ) external onlyOwner returns (bool) {
     *     bool flag = _recoverFunds(_token, _to, _amount);
     *
     *     return flag;
     * }
     * ```
     */
    function _recoverFunds(
        address _token,
        address _to,
        uint256 _amount
    ) internal returns (bool) {
        if (_token == _ZERO_ADDRESS) {
            payable(_to).transfer(_amount);
            return true;
        }

        IERC20(_token).safeTransfer(_to, _amount);

        emit TokenRecovered(_token, _to, _amount);

        return true;
    }

    event TokenRecovered(address token, address to, uint256 amount);
}