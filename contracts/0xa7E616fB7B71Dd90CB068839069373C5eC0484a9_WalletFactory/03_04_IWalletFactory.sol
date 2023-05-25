// SPDX-License-Identifier: MIT
pragma solidity 0.6.11;

interface IWalletFactory {
    function computeFutureWalletAddress(address _walletOwner) external view returns(address _walletAddress);
    function createWallet(address owner) external returns (address _walletAddress);
    function getTemplate() external view returns (address template);
    function getWalletByOwner(address owner) external view returns (address _wallet);
    function verifyWallet(address wallet) external  view returns (bool _validWallet);
    
    event WalletCreated(address indexed caller, address indexed wallet, address indexed owner);
}