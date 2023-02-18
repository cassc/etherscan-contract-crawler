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
 *     This is a modified code from Index Cooperative Inc. found at
 *
 *     https://github.com/IndexCoop/index-coop-smart-contracts
 *
 *     All changes made by Smash Works Inc. are described and documented at
 *
 *     https://docs.arch.finance/chambers
 */
pragma solidity ^0.8.17.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {WETH} from "solmate/tokens/WETH.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "solmate/utils/ReentrancyGuard.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {PreciseUnitMath} from "chambers/lib/PreciseUnitMath.sol";
import {IChamber} from "chambers/interfaces/IChamber.sol";
import {IIssuerWizard} from "chambers/interfaces/IIssuerWizard.sol";
import {ITradeIssuer} from "./interfaces/ITradeIssuer.sol";
import {IVault} from "./interfaces/IVault.sol";

contract TradeIssuer is ITradeIssuer, Ownable, ReentrancyGuard {
    /*//////////////////////////////////////////////////////////////
                              LIBRARIES
    //////////////////////////////////////////////////////////////*/

    using SafeERC20 for IERC20;
    using Address for address;
    using Address for address payable;
    using SafeERC20 for IChamber;
    using PreciseUnitMath for uint256;

    /*//////////////////////////////////////////////////////////////
                                  STORAGE
    //////////////////////////////////////////////////////////////*/

    address public immutable wrappedNativeToken;
    address public immutable dexAggregator;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    /**
     * @param _dexAggregator        Address of the dex aggregator that will be called to make the swaps.
     * @param _wrappedNativeToken   Native Token address of the chain where the contract will be deployed.
     */

    constructor(address payable _dexAggregator, address _wrappedNativeToken) {
        dexAggregator = _dexAggregator;
        wrappedNativeToken = _wrappedNativeToken;
    }

    receive() external payable {}

    /*//////////////////////////////////////////////////////////////
                            EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * Transfer the total balance of the specified stucked token to the owner address
     *
     * @param _tokenToWithdraw     The ERC20 token address to withdraw
     */
    function transferERC20ToOwner(address _tokenToWithdraw) external onlyOwner {
        require(IERC20(_tokenToWithdraw).balanceOf(address(this)) > 0, "No ERC20 Balance");

        IERC20(_tokenToWithdraw).safeTransfer(
            owner(), IERC20(_tokenToWithdraw).balanceOf(address(this))
        );
    }

    /**
     * Transfer all stucked Ether to the owner of the contract
     */
    function transferEthToOwner() external onlyOwner {
        require(address(this).balance > 0, "No Native Token balance");
        payable(owner()).transfer(address(this).balance);
    }

    /**
     * Mints chamber tokens from the network's Native Token
     *
     * @param _mintParams                IssuanceParams struct. At native token mint, chamberToken and
     *                                   baseTokenBounds are not used because chamberToken is
     *                                   the wrapped native token from the contract and the maxAmount
     *                                   is the value sent with the msg.
     *
     * @return totalNativeTokenUsed      Total amount of Native Token spent on the whole operation.
     */

    function mintChamberFromNativeToken(IssuanceParams memory _mintParams)
        external
        payable
        nonReentrant
        returns (uint256 totalNativeTokenUsed)
    {
        require(msg.value > 0, "No Native Token sent");
        WETH(payable(wrappedNativeToken)).deposit{value: msg.value}();

        _mintParams.baseToken = IERC20(wrappedNativeToken);
        _mintParams.baseTokenBounds = msg.value;

        totalNativeTokenUsed = _mintChamber(_mintParams);

        IERC20(address(_mintParams.chamber)).safeTransfer(msg.sender, _mintParams.chamberAmount);

        uint256 ethReturnAmount = msg.value - totalNativeTokenUsed;
        if (ethReturnAmount > 0) {
            WETH(payable(wrappedNativeToken)).withdraw(ethReturnAmount);
            payable(msg.sender).sendValue(ethReturnAmount);
        }

        emit TradeIssuerTokenMinted(
            address(_mintParams.chamber),
            msg.sender,
            wrappedNativeToken,
            totalNativeTokenUsed,
            _mintParams.chamberAmount
            );

        return totalNativeTokenUsed;
    }

    /**
     * Mint chamber tokens from an ERC-20 token.
     *
     * @param _mintParams                           IssuanceParams struct data for mint.
     *
     * @return totalBaseTokenUsed                  Total amount of input token spent on this issuance.
     */
    function mintChamberFromToken(IssuanceParams memory _mintParams)
        external
        nonReentrant
        returns (uint256 totalBaseTokenUsed)
    {
        _mintParams.baseToken.safeTransferFrom(
            msg.sender, address(this), _mintParams.baseTokenBounds
        );

        totalBaseTokenUsed = _mintChamber(_mintParams);

        IERC20(address(_mintParams.chamber)).safeTransfer(msg.sender, _mintParams.chamberAmount);

        if (_mintParams.baseTokenBounds - totalBaseTokenUsed > 0) {
            _mintParams.baseToken.safeTransfer(
                msg.sender, _mintParams.baseTokenBounds - totalBaseTokenUsed
            );
        }

        emit TradeIssuerTokenMinted(
            address(_mintParams.chamber),
            msg.sender,
            address(_mintParams.baseToken),
            totalBaseTokenUsed,
            _mintParams.chamberAmount
            );

        return totalBaseTokenUsed;
    }

    /**
     * Redeem chamber tokens for the network's Native Token
     *
     * @param _redeemParams                         IssuanceParams struct data for redeem.
     *
     * @return totalNativeTokenReturned             Total amount of output tokens returned to the user.
     */
    function redeemChamberToNativeToken(IssuanceParams memory _redeemParams)
        external
        nonReentrant
        returns (uint256 totalNativeTokenReturned)
    {
        IERC20(address(_redeemParams.chamber)).safeTransferFrom(
            msg.sender, address(this), _redeemParams.chamberAmount
        );

        _redeemParams.baseToken = IERC20(wrappedNativeToken);

        totalNativeTokenReturned = _redeemChamber(_redeemParams);

        require(
            totalNativeTokenReturned > _redeemParams.baseTokenBounds,
            "Redeemed for less tokens than expected"
        );

        WETH(payable(wrappedNativeToken)).withdraw(totalNativeTokenReturned);
        payable(msg.sender).sendValue(totalNativeTokenReturned);

        emit TradeIssuerTokenRedeemed(
            address(_redeemParams.chamber),
            msg.sender,
            wrappedNativeToken,
            totalNativeTokenReturned,
            _redeemParams.chamberAmount
            );

        return totalNativeTokenReturned;
    }

    /**
     * Redeem chamber tokens for an ERC-20 token.
     *
     * @param _redeemParams                         IssuanceParams struct data for redeem.
     *
     * @return totalBaseTokenReturned             Total amount of output tokens returned to the user.
     */
    function redeemChamberToToken(IssuanceParams memory _redeemParams)
        external
        nonReentrant
        returns (uint256 totalBaseTokenReturned)
    {
        IERC20(address(_redeemParams.chamber)).safeTransferFrom(
            msg.sender, address(this), _redeemParams.chamberAmount
        );

        totalBaseTokenReturned = _redeemChamber(_redeemParams);

        require(
            totalBaseTokenReturned > _redeemParams.baseTokenBounds,
            "Redeemed for less tokens than expected"
        );

        IERC20(_redeemParams.baseToken).safeTransfer(msg.sender, totalBaseTokenReturned);

        emit TradeIssuerTokenRedeemed(
            address(_redeemParams.chamber),
            msg.sender,
            address(_redeemParams.baseToken),
            totalBaseTokenReturned,
            _redeemParams.chamberAmount
            );

        return totalBaseTokenReturned;
    }

    /*//////////////////////////////////////////////////////////////
                            INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * Redeems chamber tokens for its underlying constituents, withdraws the underlying assets of ERC4626 compliant valuts,
     * and then swaps all those tokens for an output token. The msg.sender must approve this contract to use it's chamber tokens
     * beforehand.
     *
     * @param _redeemParams                       IssuanceParams struct.
     *
     * @return totalBaseTokenReturned             Total amount of input token spent on this issuance.
     */
    function _redeemChamber(IssuanceParams memory _redeemParams)
        internal
        returns (uint256 totalBaseTokenReturned)
    {
        _checkParams(_redeemParams);

        _redeemParams.issuerWizard.redeem(_redeemParams.chamber, _redeemParams.chamberAmount);

        if (_redeemParams.vaults.length > 0) {
            _withdrawConstituentsFromVault(
                _redeemParams.vaults,
                _redeemParams.vaultUnderlyingAssets,
                _redeemParams.vaultQuantities,
                _redeemParams.chamber,
                _redeemParams.chamberAmount
            );
        }

        totalBaseTokenReturned = _sellAssetsForTokenInDex(
            _redeemParams.dexQuotes,
            _redeemParams.baseToken,
            _redeemParams.components,
            _redeemParams.componentsQuantities,
            _redeemParams.swapProtectionPercentage
        );

        return totalBaseTokenReturned;
    }

    /**
     * Swaps and Deposits (if needed) required constituents using an ERC20 input token. Smart contract deposits
     * must be ERC4626 compliant, otherwise the deposit function will revert. After swaps and deposits. Chamber
     * tokens are issued.
     *
     * @param _mintParams                          IssuanceParams struct.
     *
     * @return totalBaseTokenUsed                  Total amount of input token spent on this issuance.
     */
    function _mintChamber(IssuanceParams memory _mintParams)
        internal
        returns (uint256 totalBaseTokenUsed)
    {
        _checkParams(_mintParams);

        uint256 currentAllowance =
            IERC20(_mintParams.baseToken).allowance(address(this), dexAggregator);

        if (currentAllowance < _mintParams.baseTokenBounds) {
            _mintParams.baseToken.safeIncreaseAllowance(
                dexAggregator, _mintParams.baseTokenBounds - currentAllowance
            );
        }

        _checkAndIncreaseAllowance(
            address(_mintParams.baseToken), dexAggregator, _mintParams.baseTokenBounds
        );

        totalBaseTokenUsed = _buyAssetsInDex(
            _mintParams.dexQuotes,
            _mintParams.baseToken,
            _mintParams.components,
            _mintParams.componentsQuantities,
            _mintParams.swapProtectionPercentage
        );

        require(_mintParams.baseTokenBounds >= totalBaseTokenUsed, "Overspent input/native token");

        if (_mintParams.vaults.length > 0) {
            _depositConstituentsInVault(
                _mintParams.vaults,
                _mintParams.vaultUnderlyingAssets,
                _mintParams.vaultQuantities,
                _mintParams.chamber,
                _mintParams.chamberAmount
            );
        }

        _checkAndIncreaseAllowanceOfConstituents(
            _mintParams.chamber, _mintParams.issuerWizard, _mintParams.chamberAmount
        );

        _mintParams.issuerWizard.issue(_mintParams.chamber, _mintParams.chamberAmount);

        return totalBaseTokenUsed;
    }

    /**
     * Checks all the requirements for a correct mint or redeem operation.
     *
     * @param _issuanceParams    IssuanceParams Struct.
     *
     */
    function _checkParams(IssuanceParams memory _issuanceParams) internal pure {
        require(_issuanceParams.chamberAmount > 0, "Chamber amount cannot be zero");
        require(_issuanceParams.components.length > 0, "Components array cannot be empty");
        require(
            _issuanceParams.components.length == _issuanceParams.dexQuotes.length,
            "Components and quotes must match"
        );
        require(
            _issuanceParams.components.length == _issuanceParams.componentsQuantities.length,
            "Components and qtys. must match"
        );
        require(
            _issuanceParams.vaults.length == _issuanceParams.vaultUnderlyingAssets.length,
            "Vaults and Assets must match"
        );
        require(
            _issuanceParams.vaultUnderlyingAssets.length == _issuanceParams.vaultQuantities.length,
            "Vault and Deposits must match"
        );
    }

    /**
     * Swap components using a DEX aggregator. Some of the assets may be deposited to an ERC4626 compliant contract.
     *
     * @param _dexQuotes                           The encoded array with calldata to execute in a dex aggregator contract.
     * @param _inputToken                          Token to use to pay for issuance. Must be the sellToken of the DEX Aggregator trades.
     * @param _components                          Constituents required for the chamber token or for a vault deposit.
     * @param _componentsQuantities                Constituent units needed for the chamber token or for a vault deposit.
     * @param swapProtectionPercentage       Percentage used to protect assets from being overbought or undersold at swaps.
     *
     * @return totalInputTokensUsed     Total amount of input token spent.
     */
    function _buyAssetsInDex(
        bytes[] memory _dexQuotes,
        IERC20 _inputToken,
        address[] memory _components,
        uint256[] memory _componentsQuantities,
        uint256 swapProtectionPercentage
    ) internal returns (uint256 totalInputTokensUsed) {
        uint256 componentAmountBought = 0;
        uint256 inputTokenBalanceBefore = _inputToken.balanceOf(address(this));

        for (uint256 i = 0; i < _components.length; i++) {
            require(_componentsQuantities[i] > 0, "Cannot buy zero tokens");

            // If the constituent is equal to the input token we don't have to trade
            if (_components[i] == address(_inputToken)) {
                totalInputTokensUsed += _componentsQuantities[i];
                componentAmountBought = _componentsQuantities[i];
            } else {
                uint256 componentBalanceBefore = IERC20(_components[i]).balanceOf(address(this));
                _fillQuote(_dexQuotes[i]);
                componentAmountBought =
                    IERC20(_components[i]).balanceOf(address(this)) - componentBalanceBefore;
            }
            require(
                componentAmountBought
                    <= (_componentsQuantities[i] * (1000 + swapProtectionPercentage)) / 1000,
                "Overbought dex asset"
            );
            require(componentAmountBought >= _componentsQuantities[i], "Underbought dex asset");
        }
        totalInputTokensUsed += inputTokenBalanceBefore - _inputToken.balanceOf(address(this));
    }

    /**
     * Swap components for a single output token using a DEX aggregator
     *
     * @param _dexQuotes                           The encoded array with calldata to execute in a dex aggregator contract.
     * @param _baseToken                           Token to receive on trades.
     * @param _components                          Constituents to be swapped. Must be the sellToken of the DEX Aggregator trades.
     * @param _componentsQuantities                Constituent units to be swapped.
     * @param swapProtectionPercentage       Percentage used to protect assets from being overbought or undersold at swaps.
     *
     * @return totalBaseTokenReturned Total amount of input token spent.
     */
    function _sellAssetsForTokenInDex(
        bytes[] memory _dexQuotes,
        IERC20 _baseToken,
        address[] memory _components,
        uint256[] memory _componentsQuantities,
        uint256 swapProtectionPercentage
    ) internal returns (uint256 totalBaseTokenReturned) {
        uint256 componentBalanceBefore = 0;
        uint256 outputTokenBalanceBefore = _baseToken.balanceOf(address(this));

        for (uint256 i = 0; i < _components.length; i++) {
            require(_componentsQuantities[i] > 0, "Cannot sell zero tokens");

            if (_components[i] == address(_baseToken)) {
                totalBaseTokenReturned += _componentsQuantities[i];
            } else {
                _checkAndIncreaseAllowance(_components[i], dexAggregator, _componentsQuantities[i]);
                componentBalanceBefore = IERC20(_components[i]).balanceOf(address(this));
                _fillQuote(_dexQuotes[i]);
                require(
                    IERC20(_components[i]).balanceOf(address(this))
                        <= (_componentsQuantities[i] * (swapProtectionPercentage)) / 1000,
                    "Undersold dex asset"
                );
            }
        }
        totalBaseTokenReturned += _baseToken.balanceOf(address(this)) - outputTokenBalanceBefore;
    }

    /**
     * Execute a DEX Aggregator swap quote.
     *
     * @param _quote       CallData to be executed on a DEX aggregator.
     */
    function _fillQuote(bytes memory _quote) internal returns (bytes memory response) {
        response = dexAggregator.functionCall(_quote);
        require(response.length > 0, "Low level functionCall failed");
        return (response);
    }

    /**
     * Deposits the underlying asset to an ERC4626 compliant smart contract (Vault).
     *
     * @param _vaults                   Vault constituents addresses that are part of the chamber constituents.
     * @param _vaultUnderlyingAssets    Vault underlying asset address.
     * @param _vaultQuantities          Vault underlying asset quantity needed for issuance.
     * @param _chamberAmount            Chamber token address to call the issue function.
     * @param _chamber                  Amount of the chamber token to be minted.
     */
    function _depositConstituentsInVault(
        address[] memory _vaults,
        address[] memory _vaultUnderlyingAssets,
        uint256[] memory _vaultQuantities,
        IChamber _chamber,
        uint256 _chamberAmount
    ) internal {
        for (uint256 i = 0; i < _vaults.length; i++) {
            uint256 vaultDepositAmount = _vaultQuantities[i];
            address vault = _vaults[i];
            uint256 constituentIssueQuantity = _chamber.getConstituentQuantity(vault).preciseMulCeil(
                _chamberAmount, ERC20(address(_chamber)).decimals()
            );

            require(constituentIssueQuantity > 0, "Quantity is zero");
            require(vaultDepositAmount > 0, "Deposit amount cannot be zero");

            address vaultUnderlyingAsset = _vaultUnderlyingAssets[i];
            uint256 constituentBalanceBefore = IERC20(vault).balanceOf(address(this));

            _checkAndIncreaseAllowance(vaultUnderlyingAsset, vault, vaultDepositAmount);

            IVault(vault).deposit(vaultDepositAmount);
            uint256 constituentBalanceAfter = IERC20(vault).balanceOf(address(this));
            uint256 vaultConstituentIssued = constituentBalanceAfter - constituentBalanceBefore;
            require(
                vaultConstituentIssued >= constituentIssueQuantity, "Underbought vault constituent"
            );
        }
    }

    /**
     * Withdraws ERC4626 contract shares for the original vault token.
     *
     * @param _vaults                    Vault constituents addresses that are part of the chamber constituents.
     * @param _vaultUnderlyingAssets     Vault constituents addresses that are part of the chamber constituents.
     * @param _vaultQuantities           Vault underlying assets quantity that should be received after withdraw.
     * @param _chamber                   Chamber token address.
     * @param _chamberAmount             Amount of the chamber token to be redeemed.
     */
    function _withdrawConstituentsFromVault(
        address[] memory _vaults,
        address[] memory _vaultUnderlyingAssets,
        uint256[] memory _vaultQuantities,
        IChamber _chamber,
        uint256 _chamberAmount
    ) internal {
        uint256 chamberDecimals = ERC20(address(_chamber)).decimals();
        for (uint256 i = 0; i < _vaults.length; i++) {
            uint256 expectedUnderlyingAssetsReceived = _vaultQuantities[i];
            require(expectedUnderlyingAssetsReceived > 0, "Withdraw amount cannot be zero");
            address vault = _vaults[i];
            address vaultUnderlyingAsset = _vaultUnderlyingAssets[i];
            uint256 constituentRedeemQuantity = _chamber.getConstituentQuantity(vault)
                .preciseMulCeil(_chamberAmount, chamberDecimals);

            require(constituentRedeemQuantity > 0, "Quantity is zero");

            uint256 underlyingAssetBalanceBefore =
                IERC20(vaultUnderlyingAsset).balanceOf(address(this));
            IVault(vault).withdraw(constituentRedeemQuantity);
            uint256 underlyingAssetBalanceAfter =
                IERC20(vaultUnderlyingAsset).balanceOf(address(this));

            require(
                underlyingAssetBalanceAfter - underlyingAssetBalanceBefore
                    >= expectedUnderlyingAssetsReceived,
                "Underwithdraw vault constituent"
            );
        }
    }

    /**
     * Checks the allowance for issuance of a chamberToken, if allowance is not enough it's increased to max.
     *
     * @param _chamber          Chamber token address for mint.
     * @param _issuerWizard     Issuer wizard used at _chamber.
     */
    function _checkAndIncreaseAllowanceOfConstituents(
        IChamber _chamber,
        IIssuerWizard _issuerWizard,
        uint256 _chamberAmount
    ) internal {
        require(_chamberAmount > 0, "Chamber amount cannot be zero");
        (address[] memory requiredConstituents, uint256[] memory requiredConstituentsQuantities) =
            _issuerWizard.getConstituentsQuantitiesForIssuance(_chamber, _chamberAmount);

        for (uint256 i = 0; i < requiredConstituents.length; i++) {
            _checkAndIncreaseAllowance(
                requiredConstituents[i], address(_issuerWizard), requiredConstituentsQuantities[i]
            );
        }
    }

    /**
     * For the specified token and amount, checks the allowance between the TraderIssuer and _target.
     * If not enough, it sets the maximum.
     */
    function _checkAndIncreaseAllowance(
        address _tokenAddress,
        address _target,
        uint256 _requiredAmount
    ) internal {
        require(_requiredAmount > 0, "Required amount cannot be zero");
        uint256 currentAllowance = IERC20(_tokenAddress).allowance(address(this), _target);
        if (currentAllowance < _requiredAmount) {
            IERC20(_tokenAddress).safeIncreaseAllowance(
                _target, type(uint256).max - currentAllowance
            );
        }
    }
}