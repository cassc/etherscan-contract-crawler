// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";

abstract contract ERC721VATUpgradeable is Initializable, ERC721Upgradeable {
    event IncreaseVAT(address market, uint256 tokenId, uint256 vat);
    event DecreaseVAT(address owner, uint256 tokenId, uint256 vat);
    event MarketTransaction(address market, address from, address to, uint256 tokenId);

    struct TradeInfo {
        address seller;
        address buyer;
        uint256 tokenId;
        bool used;
    }

    struct VATInfo {
        uint256 balance;
        uint256 count;
    }

    TradeInfo public currentTradeInfo;

    uint256 public totalVAT;
    uint256 public totalTransactions;

    // Mapping from token id to token VAT balance
    mapping(uint256 => VATInfo) public tokensVAT;

    function __ERC721VAT_init() internal onlyInitializing {}

    function __ERC721VAT_init_unchained() internal onlyInitializing {}

    // called by VATReceiver
    function _increaseTokenVAT(uint256 tokenId, uint256 vat) internal virtual {
        totalVAT += vat;
        currentTradeInfo.used = true;

        VATInfo storage info = tokensVAT[tokenId];
        info.balance += vat;
        info.count++;

        emit IncreaseVAT(msg.sender, tokenId, vat);
    }

    function _burn(uint256 tokenId) internal virtual override {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        VATInfo storage info = tokensVAT[tokenId];
        AddressUpgradeable.sendValue(payable(owner), info.balance);

        totalVAT -= info.balance;
        delete tokensVAT[tokenId];

        emit DecreaseVAT(owner, tokenId, info.balance);

        super._burn(tokenId);
    }

    function _tokenSecondaryMarketTransaction(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        currentTradeInfo.seller = from;
        currentTradeInfo.buyer = to;
        currentTradeInfo.tokenId = tokenId;
        currentTradeInfo.used = false;

        totalTransactions++;

        emit MarketTransaction(msg.sender, from, to, tokenId);
    }
}