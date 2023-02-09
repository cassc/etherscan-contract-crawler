// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SSBscMysteryBoxKucoinWalletLayout.sol";
import "../../../dependant/erc721improved/HERC721IMStorage.sol";
import "../../bscSPSNameServiceRef/BscSPSNameServiceRefStorage.sol";

import "./SSBscMysteryBoxKucoinWalletType.sol";

contract SSBscMysteryBoxKucoinWalletStorage is Proxy, SSBscMysteryBoxKucoinWalletLayout, HERC721IMStorage, BscSPSNameServiceRefStorage {

    constructor (
        address accessControl_,
        address owner_
    )
    Proxy(msg.sender)
    BscSPSNameServiceRefStorage(accessControl_)
    HERC721IMStorage(
        HERC721IMType.constructParam(
            SSBscMysteryBoxKucoinWalletType._name_,
            SSBscMysteryBoxKucoinWalletType._symbol_,
            SSBscMysteryBoxKucoinWalletType._uri_,
            true,
            false,
            false
        ),
        owner_
    ){
    }
}