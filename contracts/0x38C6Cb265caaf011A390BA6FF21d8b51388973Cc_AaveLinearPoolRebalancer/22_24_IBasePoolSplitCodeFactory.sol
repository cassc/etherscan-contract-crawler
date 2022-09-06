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

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "../solidity-utils/helpers/IAuthentication.sol";

interface IBasePoolSplitCodeFactory is IAuthentication {
    /**
     * @dev Returns true if `pool` was created by this factory.
     */
    function isPoolFromFactory(address pool) external view returns (bool);

    /**
     * @dev Check whether the derived factory has been disabled.
     */
    function isDisabled() external view returns (bool);

    /**
     * @dev Disable the factory, preventing the creation of more pools. Already existing pools are unaffected.
     * Once a factory is disabled, it cannot be re-enabled.
     */
    function disable() external;
}