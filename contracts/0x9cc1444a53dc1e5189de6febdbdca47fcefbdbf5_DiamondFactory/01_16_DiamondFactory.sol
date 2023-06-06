/*
 * This file is part of the Qomet Technologies contracts (https://github.com/qomet-tech/contracts).
 * Copyright (c) 2022 Qomet Technologies (https://qomet.tech)
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

pragma solidity 0.8.1;

import "@openzeppelin/contracts/interfaces/IERC165.sol";
import "./IDiamondFactory.sol";
import "./Diamond.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
contract DiamondFactory is IERC165, IDiamondFactory {

    function supportsInterface(
        bytes4 interfaceId
    ) public pure override returns (bool) {
        return interfaceId == type(IDiamondFactory).interfaceId;
    }

    function getDiamondVersion()
    external pure override returns (string memory) {
        return DiamondInfo.VERSION;
    }

    function createDiamond(
        bytes4[] memory defaultSupportingInterfceIds,
        address initializer
    ) external override returns (address) {
        Diamond diamond = new Diamond(
            defaultSupportingInterfceIds,
            initializer
        );
        return address(diamond);
    }

    fallback() external payable {
        revert("DD:FR");
    }

    receive() external payable {
        revert("DF:RR");
    }
}