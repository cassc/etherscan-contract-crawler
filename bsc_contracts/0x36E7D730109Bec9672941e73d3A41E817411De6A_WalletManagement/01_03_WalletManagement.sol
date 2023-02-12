// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract WalletManagement is Ownable {
    // ========= STRUCT ========= //
    struct WalletConfig {
        address wallet;
        string roundId;
    }

    struct WalletConfigInput {
        string key;
        WalletConfig config;
    }

    // ========= STATE VARIABLE ========= //
    mapping(string => WalletConfig) public wallets;

    // ========= EVENT ========= //
    event WalletAdded(address wallet, string roundId, string key);
    event WalletRemoved(address wallet, string roundId, string key);
    event WalletUpdated(address wallet, string roundId, string key);

    function addWallets(WalletConfigInput[] calldata _walletConfigs)
    external
    onlyOwner
    {
        for (uint256 i = 0; i < _walletConfigs.length; i++) {
            WalletConfigInput memory walletConfig = _walletConfigs[i];
            wallets[walletConfig.key] = walletConfig.config;
            emit WalletAdded(walletConfig.config.wallet, walletConfig.config.roundId, walletConfig.key);
        }
    }

    function removeWallets(string[] calldata _keys, string calldata roundId) external onlyOwner {
        for (uint256 i = 0; i < _keys.length; i++) {
            WalletConfig memory walletConfig = wallets[_keys[i]];
            delete wallets[_keys[i]];
            emit WalletRemoved(walletConfig.wallet, roundId, _keys[i]);
        }
    }

    function updateWallet(string calldata _key, WalletConfig calldata _config)
    external
    onlyOwner
    {
        wallets[_key] = _config;
        emit WalletUpdated(_config.wallet, _config.roundId, _key);
    }
}