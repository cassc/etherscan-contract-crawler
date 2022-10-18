// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

interface IMultiplier {
    function getMultiplier(uint256 duration) external pure returns (uint256);
}

contract MultiplierUpgradeable is Initializable {
    function Multiplier_init() public initializer {}

    function getMultiplier(uint256 duration) public pure returns (uint256) {
        uint256 multiplier;
        if (duration > 0 && duration <= 2629746) {
            multiplier = 10;
        } else if (duration > 2629746 && duration <= 5259492) {
            multiplier = 12;
        } else if (duration > 5259492 && duration <= 7889238) {
            multiplier = 13;
        } else if (duration > 7889238 && duration <= 10518984) {
            multiplier = 15;
        } else if (duration > 10518984 && duration <= 13148730) {
            multiplier = 17;
        } else if (duration > 13148730 && duration <= 15778476) {
            multiplier = 20;
        } else if (duration > 15778476 && duration <= 18408222) {
            multiplier = 23;
        } else if (duration > 18408222 && duration <= 21037968) {
            multiplier = 27;
        } else if (duration > 21037968 && duration <= 23667714) {
            multiplier = 31;
        } else if (duration > 23667714 && duration <= 26297460) {
            multiplier = 35;
        } else if (duration > 26297460 && duration <= 28927206) {
            multiplier = 40;
        } else if (duration > 28927206 && duration <= 31556952) {
            multiplier = 47;
        } else if (duration > 31556952 && duration <= 34186698) {
            multiplier = 54;
        } else if (duration > 34186698 && duration <= 36816444) {
            multiplier = 62;
        } else if (duration > 36816444 && duration <= 39446190) {
            multiplier = 71;
        } else if (duration > 39446190 && duration <= 42075936) {
            multiplier = 81;
        } else if (duration > 42075936 && duration <= 44705682) {
            multiplier = 94;
        } else if (duration > 44705682 && duration <= 47335428) {
            multiplier = 108;
        } else if (duration > 47335428 && duration <= 49965174) {
            multiplier = 124;
        } else if (duration > 49965174 && duration <= 52594920) {
            multiplier = 142;
        } else if (duration > 52594920 && duration <= 55224666) {
            multiplier = 164;
        } else if (duration > 55224666 && duration <= 57854412) {
            multiplier = 188;
        } else if (duration > 57854412 && duration <= 60484158) {
            multiplier = 216;
        } else if (duration > 60484158 && duration <= 63113904) {
            multiplier = 249;
        }
        return multiplier;
    }
}