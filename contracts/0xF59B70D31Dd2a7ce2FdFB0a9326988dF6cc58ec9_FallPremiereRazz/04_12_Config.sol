// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

struct Config {
    // Set to true to enable minting, provided all other valid conditions are met. If this is false, minting is
    // globally disabled except for admins.
    bool enabled;
    //
    // The root of the Merkle tree which contains an allowlist of wallets and quantities (address,uint64) that
    // can mint for free.
    bytes32 merkleRoot;
    //
    // When is minting allowed to begin.
    uint32 startTime;
    //
    // The mint price, in USD cents, per token. ($25.00 = 2500)
    uint64 mintPriceUSD;
    //
    // The amount of tokens a user can mint in this phase. This value not
    // checked before a free mint, but free mint totals are included
    // when calculating the remaining mints against a wallet limit.
    uint32 walletLimit;
    //
    // Access tokens can be used to gate access to public minting. The
    // access token must implement `balanceOf` for a given wallet.
    //
    // The access token check is ignored if accessToken is the null address
    // or minAccessTokenBalance == 0.
    address accessToken;
    uint32 minAccessTokenBalance;
}