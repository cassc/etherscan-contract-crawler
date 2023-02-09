// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SSBscMysteryBoxIdoLayout.sol";
import "../../../dependant/erc721improved/HERC721IMStorage.sol";
import "../../bscSPSNameServiceRef/BscSPSNameServiceRefStorage.sol";

import "./SSBscMysteryBoxIdoType.sol";

contract SSBscMysteryBoxIdoStorage is Proxy, SSBscMysteryBoxIdoLayout, HERC721IMStorage, BscSPSNameServiceRefStorage {

    constructor (
        address accessControl_,
        address owner_
    )
    Proxy(msg.sender)
    BscSPSNameServiceRefStorage(accessControl_)
    HERC721IMStorage(
        HERC721IMType.constructParam(
            SSBscMysteryBoxIdoType._name_,
            SSBscMysteryBoxIdoType._symbol_,
            SSBscMysteryBoxIdoType._uri_,
            true,
            false,
            false
        ),
        owner_
    ){
    }
}