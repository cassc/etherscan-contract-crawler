/**
 *     SPDX-License-Identifier: Apache License 2.0
 *
 *     Copyright 2018 Set Labs Inc.
 *     Copyright 2022 Smash Works Inc.
 *
 *     Licensed under the Apache License, Version 2.0 (the "License");
 *     you may not use this file except in compliance with the License.
 *     You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 *     Unless required by applicable law or agreed to in writing, software
 *     distributed under the License is distributed on an "AS IS" BASIS,
 *     WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *     See the License for the specific language governing permissions and
 *     limitations under the License.
 *
 *     NOTICE
 *
 *     This is a modified code from Set Labs Inc. found at
 *
 *     https://github.com/SetProtocol/set-protocol-contracts
 *
 *     All changes made by Smash Works Inc. are described and documented at
 *
 *     https://docs.arch.finance/chambers
 *
 *
 *             %@@@@@
 *          @@@@@@@@@@@
 *        #@@@@@     @@@           @@                   @@
 *       @@@@@@       @@@         @@@@                  @@
 *      @@@@@@         @@        @@  @@    @@@@@ @@@@@  @@@*@@
 *     [email protected]@@@@          @@@      @@@@@@@@   @@    @@     @@  @@
 *     @@@@@(       (((((      @@@    @@@  @@    @@@@@  @@  @@
 *    @@@@@@   (((((((
 *    @@@@@#(((((((
 *    @@@@@(((((
 *      @@@((
 */
pragma solidity ^0.8.17.0;

import {IChamber} from "./interfaces/IChamber.sol";
import {ReentrancyGuard} from "solmate/utils/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {IRebalanceWizard} from "./interfaces/IRebalanceWizard.sol";

contract RebalanceWizard is ReentrancyGuard, IRebalanceWizard {
    /*//////////////////////////////////////////////////////////////
                                 LIBRARIES
    //////////////////////////////////////////////////////////////*/

    using SafeERC20 for IERC20;
    using Address for address;

    /*//////////////////////////////////////////////////////////////
                               FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * Performs a series of trades calling a target address with the data provided.
     *
     * @param instructionsArray  RebalanceParams struct array containing all trades to perform
     */
    function rebalance(RebalanceParams[] calldata instructionsArray) external {
        for (uint256 i = 0; i < instructionsArray.length; i++) {
            _trade(instructionsArray[i]);
        }
    }

    /**
     * Trades a token for another token. It can be through a direct exchange using 0x
     * or through a deposit into a vault. The target address must be approved by the Chamber and ChamberGod.
     *
     * @param params  RebalanceParams struct containing all the necessary parameters
     */
    function _trade(RebalanceParams calldata params) internal nonReentrant {
        require(params._chamber.isManager(msg.sender), "Only managers can trade");
        require(params._sellQuantity > 0, "Sell quantity must be > 0");
        require(params._minBuyQuantity > 0, "Min. buy quantity must be > 0");
        require(params._sellToken != params._buyToken, "Traded tokens must be different");
        require(
            params._chamber.isConstituent(params._sellToken), "Sell token must be a constituent"
        );
        require(
            IERC20(params._sellToken).balanceOf(address(params._chamber)) >= params._sellQuantity,
            "Sell quantity >= chamber balance"
        );
        if (!params._chamber.isConstituent(params._buyToken)) {
            params._chamber.addConstituent(params._buyToken);
        }
        if (
            IERC20(params._sellToken).balanceOf(address(params._chamber)) - params._sellQuantity < 1
        ) {
            params._chamber.removeConstituent(params._sellToken);
        }

        uint256 tokenAmountBought = params._chamber.executeTrade(
            params._sellToken,
            params._sellQuantity,
            params._buyToken,
            params._minBuyQuantity,
            params._data,
            params._target,
            params._allowanceTarget
        );

        params._chamber.updateQuantities();

        emit TokenTraded(params._sellToken, params._buyToken, tokenAmountBought);
    }
}