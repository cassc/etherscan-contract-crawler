//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;

interface IPolygonPool {
    function stakeAndClaimBondsFor(address recepient, uint256 amount) external;

    function stakeAndClaimCertsFor(address recepient, uint256 amount) external;

    function stakeAndClaimBonds(uint256 amount) external;

    function stakeAndClaimCerts(uint256 amount) external;

    function unstakeBonds(
        uint256 amount,
        uint256 fee,
        uint256 useBeforeBlock,
        bytes memory signature
    ) external;

    function unstakeCerts(
        uint256 shares,
        uint256 fee,
        uint256 useBeforeBlock,
        bytes memory signature
    ) external;
}