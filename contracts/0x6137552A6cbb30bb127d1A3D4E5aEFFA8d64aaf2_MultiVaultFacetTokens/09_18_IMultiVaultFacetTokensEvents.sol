// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.0;


interface IMultiVaultFacetTokensEvents {
    event BlacklistTokenAdded(address token);
    event BlacklistTokenRemoved(address token);

    event TokenActivated(
        address token,
        uint activation,
        bool isNative,
        uint depositFee,
        uint withdrawFee
    );

    event TokenCreated(
        address token,
        int8 native_wid,
        uint256 native_addr,
        string name_prefix,
        string symbol_prefix,
        string name,
        string symbol,
        uint8 decimals
    );
}