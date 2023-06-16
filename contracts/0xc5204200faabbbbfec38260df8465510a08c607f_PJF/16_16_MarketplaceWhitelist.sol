// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "Ownable.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract MarketplaceWhitelist is Ownable {

    // Whitelist Marketplace contracts for easy trading.
    address internal constant openSeaProxyAddress =
        address(0xa5409ec958C83C3f309868babACA7c86DCB077c1); // OpenSea proxy
    address internal constant looksRareAddress =
        address(0xf42aa99F011A1fA7CDA90E5E98b277E306BcA83e); // LooksRare transfer manager

    bool public approveOpenSea = true;
    bool public approveLooksRare = true;

    function whitelistMarketplace(bool opensea, bool looksrare)
        external
        onlyOwner
    {
        approveOpenSea = opensea;
        approveLooksRare = looksrare;
    }
}