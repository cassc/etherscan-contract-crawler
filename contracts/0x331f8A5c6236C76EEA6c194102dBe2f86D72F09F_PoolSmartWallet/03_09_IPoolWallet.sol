// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity ^0.8.0;

/// @author RobAnon

interface IPoolWallet {

    function MASTER() external view returns (address master);

    function RESONATE() external view returns (address resonate);

    function depositAndTransfer(uint amountTokens, address vaultAddress, address smartWallet) external returns (uint shares);

    function withdraw(uint value, uint fee, address token, address recipient, address devWallet) external;

    function withdrawFromVault(uint amount, address receiver, address vault) external returns (uint tokens);

    function activateExistingConsumerPosition(
        uint amountUnderlying, 
        uint totalShares, 
        address fnftWallet,
        address devWallet,
        address vaultAdapter
    ) external returns (uint shares, uint interest);

    function activateExistingProducerPosition(
        uint amountUnderlying, 
        uint totalShares, 
        uint fee,
        address consumer,
        address devWallet,
        address vaultAdapter
    ) external returns (uint interest);
}