// SPDX-License-Identifier: AGPL-3.0-or-later

/// BaseAAveFlashLoanCommand.sol

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

import { ICommand } from "../interfaces/ICommand.sol";

import { IVault } from "../interfaces/Balancer/IVault.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { IServiceRegistry } from "../interfaces/IServiceRegistry.sol";
import { IFlashLoanRecipient } from "../interfaces/Balancer/IFlashLoanRecipient.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

abstract contract BaseBalancerFlashLoanCommand is ICommand, IFlashLoanRecipient, ReentrancyGuard {
    IServiceRegistry public immutable serviceRegistry;
    IVault public immutable balancerVault;

    address public trustedCaller;
    address public immutable self;
    address public immutable swap;

    bool public receiveExpected;

    string private constant BALANCER_VAULT = "BALANCER_VAULT";

    struct FlActionData {
        IERC20[] assets;
        uint256[] amounts;
        uint256[] premiums;
        bytes userData;
    }

    constructor(IServiceRegistry _serviceRegistry, address _swap) {
        serviceRegistry = _serviceRegistry;
        balancerVault = IVault(serviceRegistry.getRegisteredService(BALANCER_VAULT));
        swap = _swap;
        self = address(this);
    }

    function expectReceive() internal {
        receiveExpected = true;
    }

    function ethReceived() internal {
        receiveExpected = false;
    }

    function receiveFlashLoan(
        IERC20[] memory tokens,
        uint256[] memory amounts,
        uint256[] memory feeAmounts,
        bytes memory userData
    ) external {
        require(
            msg.sender == address(balancerVault),
            "(spark|aave-v3)-sl/caller-must-be-lending-pool"
        );

        bytes memory flActionData = abi.encode(FlActionData(tokens, amounts, feeAmounts, userData));

        flashloanAction(flActionData);

        for (uint256 i = 0; i < tokens.length; i++) {
            IERC20(tokens[i]).approve(address(balancerVault), amounts[i] + feeAmounts[i]);
            IERC20(tokens[i]).transfer(address(balancerVault), amounts[i] + feeAmounts[i]);
        }
    }

    function flashloanAction(bytes memory _data) internal virtual;
}