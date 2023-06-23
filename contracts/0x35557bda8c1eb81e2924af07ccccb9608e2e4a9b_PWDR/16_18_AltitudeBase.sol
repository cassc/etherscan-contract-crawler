// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import { IAddressRegistry } from "../interfaces/IAddressRegistry.sol";
import { ISnowPatrol } from "../interfaces/ISnowPatrol.sol";
import { AddressBase } from "./AddressBase.sol";

abstract contract AltitudeBase is AddressBase {
    modifier OnlyLGE {
        require(
            _msgSender() == lgeAddress(), 
            "Only the LGE contract can call this function"
        );
        _;
    }

    modifier OnlyLoyalty {
        require(
            _msgSender() == loyaltyAddress(), 
            "Only the Loyalty contract can call this function"
        );
        _;
    }

    modifier OnlyPWDR {
        require(
            _msgSender() == pwdrAddress(),
            "Only PWDR Contract can call this function"
        );
        _;
    }

    modifier OnlySlopes {
        require(
            _msgSender() == slopesAddress(), 
            "Only the Slopes contract can call this function"
        );
        _;
    }

    function avalancheAddress() internal view returns (address) {
        return IAddressRegistry(_addressRegistry).getAvalanche();
    }

    function lgeAddress() internal view returns (address) {
        return IAddressRegistry(_addressRegistry).getLGE();
    }

    function lodgeAddress() internal view returns (address) {
        return IAddressRegistry(_addressRegistry).getLodge();
    }

    function loyaltyAddress() internal view returns (address) {
        return IAddressRegistry(_addressRegistry).getLoyalty();
    }

    function pwdrAddress() internal view returns (address) {
        return IAddressRegistry(_addressRegistry).getPwdr();
    }

    function pwdrPoolAddress() internal view returns (address) {
        return IAddressRegistry(_addressRegistry).getPwdrPool();
    }

    function slopesAddress() internal view returns (address) {
        return IAddressRegistry(_addressRegistry).getSlopes();
    }

    function snowPatrolAddress() internal view returns (address) {
        return IAddressRegistry(_addressRegistry).getSnowPatrol();
    }

    function treasuryAddress() internal view returns (address) {
        return IAddressRegistry(_addressRegistry).getTreasury();
    }

    function uniswapRouterAddress() internal view returns (address) {
        return IAddressRegistry(_addressRegistry).getUniswapRouter();
    }

    function vaultAddress() internal view returns (address) {
        return IAddressRegistry(_addressRegistry).getVault();
    }

    function wethAddress() internal view returns (address) {
        return IAddressRegistry(_addressRegistry).getWeth();
    }
}