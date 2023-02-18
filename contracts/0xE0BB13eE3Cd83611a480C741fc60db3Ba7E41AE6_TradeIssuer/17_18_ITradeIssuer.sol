/**
 *     SPDX-License-Identifier: Apache License 2.0
 *
 *     Copyright 2021 Index Cooperative
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
 *     This is a modified code from Index Cooperative found at
 *
 *     https://github.com/IndexCoop/index-coop-smart-contracts
 *
 *     All changes made by Smash Works Inc. are described and documented at
 *
 *     https://docs.arch.finance/chambers
 */
pragma solidity ^0.8.17.0;

import {IChamber} from "chambers/interfaces/IChamber.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IIssuerWizard} from "chambers/interfaces/IIssuerWizard.sol";

interface ITradeIssuer {
    /*//////////////////////////////////////////////////////////////
                                 STRUCT
    //////////////////////////////////////////////////////////////*/

    /**
     * Parameters used in Mint operations.
     *
     * @param dexQuotes                            The encoded calldata array to execute in a dex aggregator.
     * @param baseToken                            Token to use to pay for issuance or expected token to receive in redeem.
     * @param baseTokenBounds                      Max amount of base token to sell when minting. Min amount to receiving when redeeming.
     * @param chamberAmount                        Amount of the chamber token to be used in transaction (mint or redeem).
     * @param chamber                              Chamber token address to call the issue function.
     * @param issuerWizard                         Instance of the issuerWizard at the _chamber.
     * @param components                           Constituents addresses that are needed for deposits to vaults or mint chamber
     *                                              token.
     * @param componentsQuantities                 Constituent quantities needed for deposits to vaults or mint chamber token.
     * @param vaults                               Vault constituents addresses that are part of the chamber constituents.
     * @param vaultUnderlyingAssets                Vault underlying asset addresses.
     * @param vaultQuantities                      Vault constituent quantities needed.
     * @param swapProtectionPercentage             Percentage used to protect assets from being overbought or undersold at swaps.
     *
     */
    struct IssuanceParams {
        bytes[] dexQuotes;
        IERC20 baseToken;
        uint256 baseTokenBounds;
        uint256 chamberAmount;
        IChamber chamber;
        IIssuerWizard issuerWizard;
        address[] components;
        uint256[] componentsQuantities;
        address[] vaults;
        address[] vaultUnderlyingAssets;
        uint256[] vaultQuantities;
        uint256 swapProtectionPercentage;
    }
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

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
                                FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function transferERC20ToOwner(address _tokenToWithdraw) external;

    function transferEthToOwner() external;

    function mintChamberFromNativeToken(IssuanceParams memory _mintParams)
        external
        payable
        returns (uint256 totalNativeTokenUsed);

    function mintChamberFromToken(IssuanceParams memory _mintParams)
        external
        returns (uint256 totalInputTokensUsed);

    function redeemChamberToNativeToken(IssuanceParams memory _redeemParams)
        external
        returns (uint256 totalNativeTokenReturned);

    function redeemChamberToToken(IssuanceParams memory _redeemParams)
        external
        returns (uint256 totalBaseTokenReturned);
}