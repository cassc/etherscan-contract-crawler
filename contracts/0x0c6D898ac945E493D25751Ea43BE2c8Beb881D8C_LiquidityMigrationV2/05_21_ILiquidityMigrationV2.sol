//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.0 <0.9.0;

interface ILiquidityMigrationV2 {
    function setStake(address user, address lp, address adapter, uint256 amount) external;

    function migrateAll(address lp, address adapter) external;
}