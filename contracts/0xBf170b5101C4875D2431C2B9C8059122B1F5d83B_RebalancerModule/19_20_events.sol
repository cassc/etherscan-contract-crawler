// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

contract Events {
    /// Emitted when stETH is deposited from vault to protocols.
    event LogVaultToProtocolDeposit(
        uint8 indexed protocol,
        uint256 depositAmount
    );

    /// Emitted whenever stETH is deposited from protcol
    /// to vault to craete withdrawal vaialability.
    event LogFillVaultAvailability(
        uint8 indexed protocol,
        uint256 withdrawAmount
    );

    /// Emitted whenever ideal Weth DSA balance is swapped to stETH.
    event LogWethSweep(uint256 wethAmount);

    /// Emitted whenever ideal Eth DSA balance is swapped to stETH.
    event LogEthSweep(uint256 ethAmount);
}