// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.0;


import "./IMultiVaultFacetTokens.sol";

interface IMultiVaultFacetDepositEvents {
    event NativeTransfer(
        int8 native_wid,
        uint256 native_addr,
        uint128 amount,
        int8 recipient_wid,
        uint256 recipient_addr,
        uint value,
        uint expected_evers,
        bytes payload
    );

    event AlienTransfer(
        uint256 base_chainId,
        uint160 base_token,
        string name,
        string symbol,
        uint8 decimals,
        uint128 amount,
        int8 recipient_wid,
        uint256 recipient_addr,
        uint value,
        uint expected_evers,
        bytes payload
    );

    event Deposit(
        IMultiVaultFacetTokens.TokenType _type,
        address sender,
        address token,
        int8 recipient_wid,
        uint256 recipient_addr,
        uint256 amount,
        uint256 fee
    );
}