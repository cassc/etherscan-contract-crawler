// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.16;

import 'src/interfaces/IERC5095.sol';
import 'src/interfaces/ISwivelToken.sol';
import 'src/interfaces/IYieldToken.sol';
import 'src/interfaces/IElementToken.sol';
import 'src/interfaces/IPendleToken.sol';
import 'src/interfaces/ITempusToken.sol';
import 'src/interfaces/ITempusPool.sol';
import 'src/interfaces/IAPWineToken.sol';
import 'src/interfaces/IAPWineFutureVault.sol';
import 'src/interfaces/IAPWineController.sol';
import 'src/interfaces/INotional.sol';

library Maturities {
    /// @notice returns the maturity for an Illumiante principal token
    /// @param p address of the principal token contract
    /// @return uint256 maturity of the principal token
    function illuminate(address p) internal view returns (uint256) {
        return IERC5095(p).maturity();
    }

    /// @notice returns the maturity for a Swivel principal token
    /// @param p address of the principal token contract
    /// @return uint256 maturity of the principal token
    function swivel(address p) internal view returns (uint256) {
        return ISwivelToken(p).maturity();
    }

    function yield(address p) internal view returns (uint256) {
        return IYieldToken(p).maturity();
    }

    /// @notice returns the maturity for an Element principal token
    /// @param p address of the principal token contract
    /// @return uint256 maturity of the principal token
    function element(address p) internal view returns (uint256) {
        return IElementToken(p).unlockTimestamp();
    }

    /// @notice returns the maturity for a Pendle principal token
    /// @param p address of the principal token contract
    /// @return uint256 maturity of the principal token
    function pendle(address p) internal view returns (uint256) {
        return IPendleToken(p).expiry();
    }

    /// @notice returns the maturity for a Tempus principal token
    /// @param p address of the principal token contract
    /// @return uint256 maturity of the principal token
    function tempus(address p) internal view returns (uint256) {
        return ITempusPool(ITempusToken(p).pool()).maturityTime();
    }

    /// @notice returns the maturity for a APWine principal token
    /// @param p address of the principal token contract
    /// @return uint256 maturity of the principal token
    function apwine(address p) internal view returns (uint256) {
        address futureVault = IAPWineToken(p).futureVault();

        address controller = IAPWineFutureVault(futureVault)
            .getControllerAddress();

        uint256 duration = IAPWineFutureVault(futureVault).PERIOD_DURATION();

        return IAPWineController(controller).getNextPeriodStart(duration);
    }

    /// @notice returns the maturity for a Notional principal token
    /// @param p address of the principal token contract
    /// @return uint256 maturity of the principal token
    function notional(address p) internal view returns (uint256) {
        return INotional(p).getMaturity();
    }
}