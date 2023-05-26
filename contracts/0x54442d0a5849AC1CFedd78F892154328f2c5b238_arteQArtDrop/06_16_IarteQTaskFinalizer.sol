/*
 * This file is part of the contracts written for artèQ Investment Fund (https://github.com/billionbuild/arteq-contracts).
 * Copyright (c) 2021 BillionBuild (2B) Team.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.0;

/// @author Kam Amini <[email protected]> <[email protected]> <[email protected]>
/// @title The interface for finalizing tasks. Mainly used by artèQ contracts to
/// perform administrative tasks in conjuction with admin contract.
interface IarteQTaskFinalizer {

    event TaskFinalized(address finalizer, address origin, uint256 taskId);

    function finalizeTask(address origin, uint256 taskId) external;
}