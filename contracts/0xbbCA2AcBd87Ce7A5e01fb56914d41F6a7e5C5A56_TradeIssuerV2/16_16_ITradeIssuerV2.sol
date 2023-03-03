/**
 *     SPDX-License-Identifier: Apache License 2.0
 *
 *     Copyright 2021 Index Cooperative
 *     Copyright 2023 Smash Works Inc.
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
 *     This is a modified code from Index Cooperative found at
 *
 *     https://github.com/IndexCoop/index-coop-smart-contracts
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

import {IChamber} from "chambers/interfaces/IChamber.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IIssuerWizard} from "chambers/interfaces/IIssuerWizard.sol";

interface ITradeIssuerV2 {
    /*//////////////////////////////////////////////////////////////
                               STRUCTS
    //////////////////////////////////////////////////////////////*/

    struct ContractCallInstruction {
        address payable _target;
        address _allowanceTarget;
        IERC20 _sellToken;
        uint256 _sellAmount;
        IERC20 _buyToken;
        uint256 _minBuyAmount;
        bytes _callData;
    }

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event AllowedTargetAdded(address indexed _target);

    event AllowedTargetRemoved(address indexed _targer);

    event TradeIssuerTokenMinted(
        address indexed chamber,
        address indexed recipient,
        address indexed inputToken,
        uint256 totalTokensUsed,
        uint256 mintAmount
    );

    event TradeIssuerTokenRedeemed(
        address indexed chamber,
        address indexed recipient,
        address indexed outputToken,
        uint256 totalTokensReturned,
        uint256 redeemAmount
    );

    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    error CannotAllowTarget();

    error CannotRemoveTarget();

    error InvalidTarget(address target);

    error LowLevelFunctionCallFailed();

    error OversoldBaseToken();

    error RedeemedForLessTokens();

    error TargetAlreadyAllowed();

    error UnderboughtAsset(IERC20 asset, uint256 buyAmount);

    error UnderboughtConstituent(IERC20 asset, uint256 buyAmount);

    error ZeroChamberAmount();

    error ZeroBalanceAsset();

    error ZeroNativeTokenSent();

    error ZeroRequiredAmount();

    /*//////////////////////////////////////////////////////////////
                                FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function getAllowedTargets() external returns (address[] memory);

    function isAllowedTarget(address _target) external returns (bool);

    function addTarget(address _target) external;

    function removeTarget(address _target) external;

    function transferERC20ToOwner(address _tokenToWithdraw) external;

    function transferEthToOwner() external;

    function mintChamberFromToken(
        ContractCallInstruction[] memory _contractCallInstructions,
        IChamber _chamber,
        IIssuerWizard _issuerWizard,
        IERC20 _baseToken,
        uint256 _maxPayAmount,
        uint256 _chamberAmount
    ) external returns (uint256 baseTokenUsed);

    function mintChamberFromNativeToken(
        ContractCallInstruction[] memory _contractCallInstructions,
        IChamber _chamber,
        IIssuerWizard _issuerWizard,
        uint256 _chamberAmount
    ) external payable returns (uint256 wrappedNativeTokenUsed);

    function redeemChamberToToken(
        ContractCallInstruction[] memory _contractCallInstructions,
        IChamber _chamber,
        IIssuerWizard _issuerWizard,
        IERC20 _baseToken,
        uint256 _minReceiveAmount,
        uint256 _chamberAmount
    ) external returns (uint256 baseTokenReturned);

    function redeemChamberToNativeToken(
        ContractCallInstruction[] memory _contractCallInstructions,
        IChamber _chamber,
        IIssuerWizard _issuerWizard,
        uint256 _minReceiveAmount,
        uint256 _chamberAmount
    ) external returns (uint256 wrappedNativeTokenReturned);
}