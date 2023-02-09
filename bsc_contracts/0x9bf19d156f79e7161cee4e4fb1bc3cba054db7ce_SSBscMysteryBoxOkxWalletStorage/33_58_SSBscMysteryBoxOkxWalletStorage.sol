// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SSBscMysteryBoxOkxWalletLayout.sol";
import "../../../dependant/erc721improved/HERC721IMStorage.sol";
import "../../bscSPSNameServiceRef/BscSPSNameServiceRefStorage.sol";

import "./SSBscMysteryBoxOkxWalletType.sol";

contract SSBscMysteryBoxOkxWalletStorage is Proxy, SSBscMysteryBoxOkxWalletLayout, HERC721IMStorage, BscSPSNameServiceRefStorage {

    constructor (
        address accessControl_,
        address owner_
    )
    Proxy(msg.sender)
    BscSPSNameServiceRefStorage(accessControl_)
    HERC721IMStorage(
        HERC721IMType.constructParam(
            SSBscMysteryBoxOkxWalletType._name_,
            SSBscMysteryBoxOkxWalletType._symbol_,
            SSBscMysteryBoxOkxWalletType._uri_,
            true,
            false,
            false
        ),
        owner_
    ){
    }
}