// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

import {IERC20} from "openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC1155} from "openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {ERC1155Holder} from "openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

import {ICodex} from "fiat/interfaces/ICodex.sol";
import {IPublican} from "fiat/interfaces/IPublican.sol";
import {IMoneta} from "fiat/interfaces/IMoneta.sol";
import {IFIAT} from "fiat/interfaces/IFIAT.sol";
import {IVault} from "fiat/interfaces/IVault.sol";
import {WAD, toInt256, sub, wmul, wdiv} from "fiat/utils/Math.sol";

/// @title VaultActions
/// @notice A set of base vault actions to inherited from
abstract contract VaultActions {
    /// ======== Custom Errors ======== ///

    error VaultActions__exitMoneta_zeroUserAddress();

    /// ======== Storage ======== ///

    /// @notice Codex
    ICodex public immutable codex;
    /// @notice Moneta
    IMoneta public immutable moneta;
    /// @notice FIAT token
    IFIAT public immutable fiat;
    /// @notice Publican
    IPublican public immutable publican;

    constructor(
        address codex_,
        address moneta_,
        address fiat_,
        address publican_
    ) {
        codex = ICodex(codex_);
        moneta = IMoneta(moneta_);
        fiat = IFIAT(fiat_);
        publican = IPublican(publican_);
    }

    /// @notice Sets `amount` as the allowance of `spender` over the UserProxy's FIAT
    /// @param spender Address of the spender
    /// @param amount Amount of tokens to approve [wad]
    function approveFIAT(address spender, uint256 amount) external {
        fiat.approve(spender, amount);
    }

    /// @dev Redeems FIAT for internal credit
    /// @param to Address of the recipient
    /// @param amount Amount of FIAT to exit [wad]
    function exitMoneta(address to, uint256 amount) public {
        if (to == address(0)) revert VaultActions__exitMoneta_zeroUserAddress();

        // proxy needs to delegate ability to transfer internal credit on its behalf to Moneta first
        if (codex.delegates(address(this), address(moneta)) != 1) codex.grantDelegate(address(moneta));

        moneta.exit(to, amount);
    }

    /// @dev The user needs to previously call approveFIAT with the address of Moneta as the spender
    /// @param from Address of the account which provides FIAT
    /// @param amount Amount of FIAT to enter [wad]
    function enterMoneta(address from, uint256 amount) public {
        // if `from` is set to an external address then transfer amount to the proxy first
        // requires `from` to have set an allowance for the proxy
        if (from != address(0) && from != address(this)) fiat.transferFrom(from, address(this), amount);

        moneta.enter(address(this), amount);
    }

    /// @notice Deposits `amount` of `token` with `tokenId` from `from` into the `vault`
    /// @dev Virtual method to be implement in token specific UserAction contracts
    function enterVault(
        address vault,
        address token,
        uint256 tokenId,
        address from,
        uint256 amount
    ) public virtual;

    /// @notice Withdraws `amount` of `token` with `tokenId` to `to` from the `vault`
    /// @dev Virtual method to be implement in token specific UserAction contracts
    function exitVault(
        address vault,
        address token,
        uint256 tokenId,
        address to,
        uint256 amount
    ) public virtual;

    /// @notice method for adjusting collateral and debt balances of a position.
    /// 1. updates the interest rate accumulator for the given vault
    /// 2. enters FIAT into Moneta if deltaNormalDebt is negative (applies rate to deltaNormalDebt)
    /// 3. enters Collateral into Vault if deltaCollateral is positive
    /// 3. modifies collateral and debt balances in Codex
    /// 4. exits FIAT from Moneta if deltaNormalDebt is positive (applies rate to deltaNormalDebt)
    /// 5. exits Collateral from Vault if deltaCollateral is negative
    /// @dev The user needs to previously approve the UserProxy for spending collateral tokens or FIAT tokens
    /// If `position` is not the UserProxy, the `position` owner needs grant a delegate to UserProxy via Codex
    /// @param vault Address of the Vault
    /// @param token Address of the vault's collateral token
    /// @param tokenId ERC1155 or ERC721 style TokenId (leave at 0 for ERC20)
    /// @param position Address of the position's owner
    /// @param collateralizer Address of who puts up or receives the collateral delta
    /// @param creditor Address of who provides or receives the FIAT delta for the debt delta
    /// @param deltaCollateral Amount of collateral to put up (+) for or remove (-) from this Position [wad]
    /// @param deltaNormalDebt Amount of normalized debt (gross, before rate is applied) to generate (+) or
    /// settle (-) for this Position [wad]
    function modifyCollateralAndDebt(
        address vault,
        address token,
        uint256 tokenId,
        address position,
        address collateralizer,
        address creditor,
        int256 deltaCollateral,
        int256 deltaNormalDebt
    ) public {
        // update the interest rate accumulator in Codex for the vault
        if (deltaNormalDebt != 0) publican.collect(vault);

        if (deltaNormalDebt < 0) {
            // add due interest from normal debt
            (, uint256 rate, , ) = codex.vaults(vault);
            enterMoneta(creditor, uint256(-wmul(rate, deltaNormalDebt)));
        }

        // transfer tokens to be used as collateral into Vault
        if (deltaCollateral > 0) {
            enterVault(
                vault,
                token,
                tokenId,
                collateralizer,
                wmul(uint256(deltaCollateral), IVault(vault).tokenScale())
            );
        }

        // update collateral and debt balanaces
        codex.modifyCollateralAndDebt(
            vault,
            tokenId,
            position,
            address(this),
            address(this),
            deltaCollateral,
            deltaNormalDebt
        );

        // redeem newly generated internal credit for FIAT
        if (deltaNormalDebt > 0) {
            // forward all generated credit by applying rate
            (, uint256 rate, , ) = codex.vaults(vault);
            exitMoneta(creditor, wmul(uint256(deltaNormalDebt), rate));
        }

        // withdraw tokens not be used as collateral anymore from Vault
        if (deltaCollateral < 0) {
            exitVault(
                vault,
                token,
                tokenId,
                collateralizer,
                wmul(uint256(-deltaCollateral), IVault(vault).tokenScale())
            );
        }
    }
}