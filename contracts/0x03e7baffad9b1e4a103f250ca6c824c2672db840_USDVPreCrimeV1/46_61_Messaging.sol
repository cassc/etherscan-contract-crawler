// SPDX-License-Identifier: LZBL-1.1
// Copyright 2023 LayerZero Labs Ltd.
// You may obtain a copy of the License at
// https://github.com/LayerZero-Labs/license/blob/main/LICENSE-LZBL-1.1

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import {IMessaging} from "./interfaces/IMessaging.sol";
import {IUSDV} from "../usdv/interfaces/IUSDV.sol";
import {IVaultManager} from "../vault/interfaces/IVaultManager.sol";

abstract contract Messaging is Ownable, IMessaging {
    uint32 public immutable mainChainEid;
    bool public immutable isMainChain;

    address public immutable usdv;

    mapping(uint32 dstEid => mapping(uint8 msgType => uint extraGas)) public perColorExtraGasLookup;

    constructor(address _usdv, uint32 _mainChainEid, bool _isMainChain) {
        usdv = _usdv;
        mainChainEid = _mainChainEid;
        isMainChain = _isMainChain;
    }

    modifier onlyUSDV() {
        if (msg.sender != usdv) revert NotUSDV(msg.sender);
        _;
    }

    // ======================== onlyOwner ========================
    function setPerColorExtraGas(uint32 _dstEid, uint8 _msgType, uint _extraGas) external onlyOwner {
        perColorExtraGasLookup[_dstEid][_msgType] = _extraGas;
        emit SetPerColorExtraGas(_dstEid, _msgType, _extraGas);
    }
}