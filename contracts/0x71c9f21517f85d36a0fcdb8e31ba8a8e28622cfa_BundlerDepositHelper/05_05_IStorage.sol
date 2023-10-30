// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

interface IStorage {
    struct bundlerInformation {
        address bundler;
        uint256 registeTime;
    }
    event UnrestrictedWalletSet(bool allowed);
    event UnrestrictedBundlerSet(bool allowed);
    event UnrestrictedModuleSet(bool allowed);
    event WalletFactoryWhitelistSet(address walletProxyFactory);
    event BundlerWhitelistSet(address indexed bundler, bool allowed);
    event ModuleWhitelistSet(address indexed module, bool allowed);

    function officialBundlerWhiteList(
        address bundler
    ) external view returns (bool);

    function moduleWhiteList(address module) external view returns (bool);

    function setUnrestrictedWallet(bool allowed) external;

    function setUnrestrictedBundler(bool allowed) external;

    function setUnrestrictedModule(bool allowed) external;

    function setBundlerOfficialWhitelist(
        address bundler,
        bool allowed
    ) external;

    function setWalletProxyFactoryWhitelist(address walletFactory) external;

    function setModuleWhitelist(address module, bool allowed) external;

    function validateModuleWhitelist(address module) external;

    function validateWalletWhitelist(address sender) external view;
}