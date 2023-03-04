// SPDX-License-Identifier: LGPL-3.0-only
// Creatd By: Art Blocks Inc.

pragma solidity ^0.8.0;

interface IBonusContract {
    function triggerBonus(address _to) external returns (bool);

    function bonusIsActive() external view returns (bool);
}