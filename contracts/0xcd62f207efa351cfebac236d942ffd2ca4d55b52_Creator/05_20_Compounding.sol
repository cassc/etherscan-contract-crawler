// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.13;

import 'src/Protocols.sol';

import 'src/lib/LibCompound.sol';

import 'src/interfaces/IERC4626.sol';
import 'src/interfaces/ICERC20.sol';
import 'src/interfaces/IAavePool.sol';
import 'src/interfaces/IAaveToken.sol';
import 'src/interfaces/IEulerToken.sol';
import 'src/interfaces/ICompoundToken.sol';
import 'src/interfaces/ILidoToken.sol';
import 'src/interfaces/IYearnVault.sol';

library Compounding {
    /// @param p Protocol Enum value
    /// @param c Compounding token address
    function underlying(uint8 p, address c) internal view returns (address) {
        if (p == uint8(Protocols.Compound) || p == uint8(Protocols.Rari)) {
            return ICompoundToken(c).underlying();
        } else if (p == uint8(Protocols.Yearn)) {
            return IYearnVault(c).token();
        } else if (p == uint8(Protocols.Aave)) {
            return IAaveToken(c).UNDERLYING_ASSET_ADDRESS();
        } else if (p == uint8(Protocols.Euler)) {
            return IEulerToken(c).underlyingAsset();
        } else if (p == uint8(Protocols.Lido)) {
            return ILidoToken(c).stETH();
        } else {
            return IERC4626(c).asset();
        }
    }

    /// @param p Protocol Enum value
    /// @param c Compounding token address
    function exchangeRate(uint8 p, address c) internal returns (uint256) {
        // in contrast to the below, LibCompound provides a lower gas alternative to exchangeRateCurrent()
        if (p == uint8(Protocols.Compound)) {
            return LibCompound.viewExchangeRate(ICERC20(c));
            // with the removal of LibFuse we will direct Rari to the exposed Compound CToken methodology
        } else if (p == uint8(Protocols.Rari)) {
            return ICompoundToken(c).exchangeRateCurrent();
        } else if (p == uint8(Protocols.Yearn)) {
            return IYearnVault(c).pricePerShare();
        } else if (p == uint8(Protocols.Aave)) {
            IAaveToken aToken = IAaveToken(c);
            return
                IAavePool(aToken.POOL()).getReserveNormalizedIncome(
                    aToken.UNDERLYING_ASSET_ADDRESS()
                );
        } else if (p == uint8(Protocols.Euler)) {
            // NOTE: the 1e26 const is a degree of precision to enforce on the return
            return IEulerToken(c).convertBalanceToUnderlying(1e26);
        } else if (p == uint8(Protocols.Lido)) {
            return ILidoToken(c).stEthPerToken();
        } else {
            // NOTE: the 1e26 const is a degree of precision to enforce on the return
            return IERC4626(c).convertToAssets(1e26);
        }
    }
}