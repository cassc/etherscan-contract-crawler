// SPDX-FileCopyrightText: © 2023 Dai Foundation <www.daifoundation.org>
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.
pragma solidity =0.8.19;

/**
 * @title SubProxy: the SubDAO-level `PauseProxy`.
 * @dev This proxy uses `delegatecall` to execute calls from context isolated from the main governance contract.
 * Contracts that must be controlled by SubDAO governance must authorize the `SubProxy` contract instead of the
 * governance contract itself.
 * @author @amusingaxl
 */
contract SubProxy {
    /// @notice Addresses with owner access on this contract. `wards[usr]`
    mapping(address => uint256) public wards;

    /**
     * @notice `usr` was granted owner access.
     * @param usr The user address.
     */
    event Rely(address indexed usr);
    /**
     * @notice `usr` owner access was revoked.
     * @param usr The user address.
     */
    event Deny(address indexed usr);

    modifier auth() {
        require(wards[msg.sender] == 1, "SubProxy/not-authorized");
        _;
    }

    constructor() {
        wards[msg.sender] = 1;
        emit Rely(msg.sender);
    }

    /**
     * @notice Grants `usr` admin access to this contract.
     * @param usr The user address.
     */
    function rely(address usr) external auth {
        wards[usr] = 1;
        emit Rely(usr);
    }

    /**
     * @notice Revokes `usr` admin access from this contract.
     * @param usr The user address.
     */
    function deny(address usr) external auth {
        wards[usr] = 0;
        emit Deny(usr);
    }

    /**
     * @notice Executes a calldata-encoded call `args` in the context of `target`.
     * @param target The target contract.
     * @param args The calldata-encoded call.
     * @return out The result of the execution.
     */
    function exec(address target, bytes calldata args) external payable auth returns (bytes memory out) {
        bool ok;
        (ok, out) = target.delegatecall(args);
        require(ok, "SubProxy/delegatecall-error");
    }
}