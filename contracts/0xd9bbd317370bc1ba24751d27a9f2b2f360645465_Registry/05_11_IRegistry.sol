// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IRegistry {
    function listingBeacon() external returns (UpgradeableBeacon);

    function brickTokenBeacon() external returns (UpgradeableBeacon);

    function buyoutBeacon() external returns (UpgradeableBeacon);

    function iroBeacon() external returns (UpgradeableBeacon);

    function propNFT() external returns (IERC721);

    function treasuryAddr() external returns (address);
}