// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/utils/Address.sol';

import './BaseAction.sol';

abstract contract ReceiverAction is BaseAction {
    using SafeERC20 for IERC20;

    receive() external payable {
        // solhint-disable-previous-line no-empty-blocks
    }

    function withdraw(address token, uint256 amount) external auth {
        _withdraw(token, amount);
    }

    function _withdraw(address token, uint256 amount) internal {
        Denominations.isNativeToken(token)
            ? Address.sendValue(payable(address(smartVault)), amount)
            : IERC20(token).safeTransfer(address(smartVault), amount);
    }
}