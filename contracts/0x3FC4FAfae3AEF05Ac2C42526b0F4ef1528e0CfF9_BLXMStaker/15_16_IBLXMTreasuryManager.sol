// SPDX-License-Identifier: GPL-3.0 License

pragma solidity ^0.8.0;


interface IBLXMTreasuryManager {

    event UpdateTreasury(address indexed sender, address oldTreasury, address newTreasury);

    function updateTreasury(address treasury) external;
    function getTreasury() external returns (address treasury);

    function getReserves() external view returns (uint reserveBlxm, uint totalRewrads);
}