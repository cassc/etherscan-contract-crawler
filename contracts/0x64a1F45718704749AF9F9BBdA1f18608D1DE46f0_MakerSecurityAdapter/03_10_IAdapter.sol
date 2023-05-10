// SPDX-License-Identifier: AGPL-3.0-or-later

/// IAdapter.sol

// Copyright (C) 2023 Oazo Apps Limited

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
pragma solidity ^0.8.0;

interface ISecurityAdapter {
    function canCall(bytes memory triggerData, address operator) external returns (bool);

    function permit(bytes memory triggerData, address target, bool allowance) external;
}

interface IExecutableAdapter {
    function getCoverage(
        bytes memory triggerData,
        address receiver,
        address token,
        uint256 amount
    ) external;
}