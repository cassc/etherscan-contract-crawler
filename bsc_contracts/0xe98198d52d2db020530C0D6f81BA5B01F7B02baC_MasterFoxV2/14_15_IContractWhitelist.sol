// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

/*
// FOX BLOCKCHAIN \\

FoxChain works to connect all Blockchains in one platform with one click access to any network.

Website     : https://foxchain.app/
Dex         : https://foxdex.finance/
Telegram    : https://t.me/FOXCHAINNEWS
Twitter     : https://twitter.com/FoxchainLabs
Github      : https://github.com/FoxChainLabs

*/

interface IContractWhitelist {
    function getWhitelistLength() external returns (uint256);

    function getWhitelistAtIndex(uint256 _index) external returns (address);

    function isWhitelisted(address _address) external returns (bool);

    function setWhitelistEnabled(bool _enabled) external;

    function setContractWhitelist(address _address, bool _enabled) external;

    function setBatchContractWhitelist(
        address[] memory _addresses,
        bool[] memory _enabled
    ) external;
}