// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

interface IBondFactory {
    function createBond(
        address _collateralToken,
        uint256[] memory trancheRatios,
        uint256 maturityDate
    ) external returns (address);
}