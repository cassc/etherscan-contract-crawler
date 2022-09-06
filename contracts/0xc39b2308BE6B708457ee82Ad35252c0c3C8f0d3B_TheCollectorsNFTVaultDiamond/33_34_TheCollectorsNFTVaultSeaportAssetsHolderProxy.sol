// SPDX-License-Identifier: UNLICENSED
// © 2022 The Collectors. All rights reserved.
pragma solidity ^0.8.13;

import "./Imports.sol";
import "./LibDiamond.sol";
import "./TheCollectorsNFTVaultSeaportAssetsHolderImpl.sol";

/*
    -----_______.-_______------___------.______-----______---.______-----.___________.
    ----/-------||---____|----/---\-----|---_--\---/--__--\--|---_--\----|-----------|
    ---|---(----`|--|__------/--^--\----|--|_)--|-|--|--|--|-|--|_)--|---`---|--|----`
    ----\---\----|---__|----/--/_\--\---|---___/--|--|--|--|-|------/--------|--|-----
    .----)---|---|--|____--/--_____--\--|--|------|--`--'--|-|--|\--\----.---|--|-----
    |_______/----|_______|/__/-----\__\-|-_|-------\______/--|-_|-`._____|---|__|-----
    -----___-----------_______.-----_______.-_______-.___________.----_______.--------
    ----/---\---------/-------|----/-------||---____||-----------|---/-------|--------
    ---/--^--\-------|---(----`---|---(----`|--|__---`---|--|----`--|---(----`--------
    --/--/_\--\-------\---\--------\---\----|---__|------|--|--------\---\------------
    -/--_____--\--.----)---|---.----)---|---|--|____-----|--|----.----)---|-----------
    /__/-----\__\-|_______/----|_______/----|_______|----|__|----|_______/------------
    -__----__----______----__-------_______---_______-.______-------------------------
    |--|--|--|--/--__--\--|--|-----|-------\-|---____||---_--\------------------------
    |--|__|--|-|--|--|--|-|--|-----|--.--.--||--|__---|--|_)--|-----------------------
    |---__---|-|--|--|--|-|--|-----|--|--|--||---__|--|------/------------------------
    |--|--|--|-|--`--'--|-|--`----.|--'--'--||--|____-|--|\--\----.-------------------
    |__|--|__|--\______/--|_______||_______/-|_______||-_|-`._____|-------------------
    .______---.______--------______---___---___-____----____--------------------------
    |---_--\--|---_--\------/--__--\--\--\-/--/-\---\--/---/--------------------------
    |--|_)--|-|--|_)--|----|--|--|--|--\--V--/---\---\/---/---------------------------
    |---___/--|------/-----|--|--|--|--->---<-----\_----_/----------------------------
    |--|------|--|\--\----.|--`--'--|--/--.--\------|--|------------------------------
    |-_|------|-_|-`._____|-\______/--/__/-\__\-----|__|------------------------------
    ----------------------------------------------------------------------------------
    @dev
    The contract that will hold the assets and ETH for each vault.
    Working together with @TheCollectorsNFTVaultSeaportAssetsHolderImpl in a proxy/implementation design pattern.
    The reason why it is separated to proxy and implementation is to save gas when creating vaults
*/
contract TheCollectorsNFTVaultSeaportAssetsHolderProxy {

    constructor(address impl, uint64 _vaultId) {
        LibDiamond.AssetsHolderStorage storage ahs = _getAssetsHolderStorage();
        ahs.implementation = impl;
        ahs.vaultId = _vaultId;
        ahs.owner = msg.sender;
    }

    // ==================== Proxy ====================

    fallback() external payable virtual {
        address implementation = _getAssetsHolderStorage().implementation;
        assembly {
        // Copy msg.data. We take full control of memory in this inline assembly
        // block because it will not return to Solidity code. We overwrite the
        // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

        // Call the implementation.
        // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

        // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return (0, returndatasize())
            }
        }
    }

    // ==================== Internals ====================

    function _getAssetsHolderStorage() internal pure returns (LibDiamond.AssetsHolderStorage storage ahs) {
        bytes32 position = LibDiamond.ASSETS_HOLDER_STORAGE_POSITION;
        assembly {
            ahs.slot := position
        }
    }

}