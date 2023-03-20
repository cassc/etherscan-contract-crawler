// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

interface IBurnPool {
    error ZeroRebornTokenSet();
    error ZeroOwnerSet();

    event Burn(uint256 amount);

    // burn expect amount of $REBORN
    function burn(uint256 amount) external;
}