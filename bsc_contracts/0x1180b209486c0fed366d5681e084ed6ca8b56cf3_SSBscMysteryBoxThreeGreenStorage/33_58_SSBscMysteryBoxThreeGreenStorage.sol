// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SSBscMysteryBoxThreeGreenLayout.sol";
import "../../../dependant/erc721improved/HERC721IMStorage.sol";
import "../../bscSPSNameServiceRef/BscSPSNameServiceRefStorage.sol";

import "./SSBscMysteryBoxThreeGreenType.sol";

contract SSBscMysteryBoxThreeGreenStorage is Proxy, SSBscMysteryBoxThreeGreenLayout, HERC721IMStorage, BscSPSNameServiceRefStorage {

    constructor (
        address accessControl_,
        address owner_
    )
    Proxy(msg.sender)
    BscSPSNameServiceRefStorage(accessControl_)
    HERC721IMStorage(
        HERC721IMType.constructParam(
            SSBscMysteryBoxThreeGreenType._name_,
            SSBscMysteryBoxThreeGreenType._symbol_,
            SSBscMysteryBoxThreeGreenType._uri_,
            true,
            false,
            false
        ),
        owner_
    ){
    }
}