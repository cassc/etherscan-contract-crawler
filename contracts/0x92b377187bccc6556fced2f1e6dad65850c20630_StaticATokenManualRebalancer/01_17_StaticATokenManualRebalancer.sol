// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "@balancer-labs/v2-interfaces/contracts/vault/IVault.sol";
import "@balancer-labs/v2-solidity-utils/contracts/openzeppelin/Address.sol";
import "@balancer-labs/v2-interfaces/contracts/pool-linear/ILinearPool.sol";
import "@balancer-labs/v2-interfaces/contracts/standalone-utils/IBGDStaticATokenLM.sol";


contract StaticATokenManualRebalancer {
    IVault public immutable vault;

    constructor(IVault _vault) {
        vault = _vault;
    }

    function wrap(
        bytes32 linearPoolId,
        uint256 numLoops,
        uint256 mainTokenAmountOrZeroForAll
    ) external returns (uint256) {
        address caller = msg.sender;
        (IERC20 mainToken, IERC20 wrappedToken, IBGDStaticATokenLM vaultToken) = _getLinearPoolTokens(linearPoolId);

        //if wrap is called with 0, we use the full balance of the caller
        uint256 amountToWrap = mainTokenAmountOrZeroForAll == 0
            ? mainToken.balanceOf(caller)
            : mainTokenAmountOrZeroForAll;

        // pull main tokens to the rebalancer
        mainToken.transferFrom(caller, address(this), amountToWrap);

        _setVaultAllowancesIfNeeded(mainToken, wrappedToken);

        for (uint256 i = 0; i < numLoops; ++i) {
            // Deposit the tokens into the vault
            vaultToken.deposit(mainToken.balanceOf(address(this)), address(this), 0, true);

            // swap wrappedToken -> mainToken
            IVault.SingleSwap memory swap = IVault.SingleSwap({
                poolId: linearPoolId,
                kind: IVault.SwapKind.GIVEN_IN,
                assetIn: IAsset(address(wrappedToken)),
                assetOut: IAsset(address(mainToken)),
                amount: vaultToken.balanceOf(address(this)),
                userData: "0x"
            });

            IVault.FundManagement memory funds = IVault.FundManagement({
                sender: address(this),
                fromInternalBalance: false,
                recipient: payable(address(this)),
                toInternalBalance: false
            });

            vault.swap(swap, funds, 0, type(uint256).max);
        }

        uint256 mainTokenEndBalance = mainToken.balanceOf(address(this));
        mainToken.transfer(caller, mainTokenEndBalance);
      
        return mainTokenEndBalance;
    }

    function unwrap(
        bytes32 linearPoolId,
        uint256 numLoops,
        uint256 mainTokenAmountOrZeroForAll
    ) external returns (uint256) {
        address caller = msg.sender;
        (IERC20 mainToken, IERC20 wrappedToken, IBGDStaticATokenLM vaultToken) = _getLinearPoolTokens(linearPoolId);

        //if unwrap is called with 0, we use the full balance of the caller
        uint256 amount = mainTokenAmountOrZeroForAll == 0
            ? mainToken.balanceOf(caller)
            : mainTokenAmountOrZeroForAll;

        // pull main tokens to the rebalancer
        mainToken.transferFrom(caller, address(this), amount);

        _setVaultAllowancesIfNeeded(mainToken, wrappedToken);

        for (uint256 i = 0; i < numLoops; ++i) {
            // swap mainToken -> wrappedToken
            IVault.SingleSwap memory swap = IVault.SingleSwap({
                poolId: linearPoolId,
                kind: IVault.SwapKind.GIVEN_IN,
                assetIn: IAsset(address(mainToken)),
                assetOut: IAsset(address(wrappedToken)),
                amount: mainToken.balanceOf(address(this)),
                userData: "0x"
            });

            IVault.FundManagement memory funds = IVault.FundManagement({
                sender: address(this),
                fromInternalBalance: false,
                recipient: payable(address(this)),
                toInternalBalance: false
            });

            vault.swap(swap, funds, 0, type(uint256).max);

            // Redeem the vault tokens to receive main tokens
            vaultToken.redeem(vaultToken.balanceOf(address(this)), address(this), address(this), true);      
        }

        uint256 mainTokenEndBalance = mainToken.balanceOf(address(this));
        mainToken.transfer(caller, mainTokenEndBalance);
      
        return mainTokenEndBalance;
    }

    function _getLinearPoolTokens(
        bytes32 linearPoolId
    ) internal view returns (IERC20 mainToken, IERC20 wrappedToken, IBGDStaticATokenLM vaultToken) {
        (address poolAddress, ) = vault.getPool(linearPoolId);
        ILinearPool linearPool = ILinearPool(poolAddress);

        mainToken = linearPool.getMainToken();
        wrappedToken = linearPool.getWrappedToken();
        vaultToken = IBGDStaticATokenLM(address(wrappedToken));
    }

    function _setVaultAllowancesIfNeeded(
        IERC20 mainToken,
        IERC20 wrappedToken
    ) internal {
        // we set max allowance once
        if (mainToken.allowance(address(this), address(wrappedToken)) == 0) {
            mainToken.approve(address(wrappedToken), type(uint256).max);
        }

        if (wrappedToken.allowance(address(this), address(vault)) == 0) {
            wrappedToken.approve(address(vault), type(uint256).max);
        }

        if (mainToken.allowance(address(this), address(vault)) == 0) {
            mainToken.approve(address(vault), type(uint256).max);
        }
    }
}