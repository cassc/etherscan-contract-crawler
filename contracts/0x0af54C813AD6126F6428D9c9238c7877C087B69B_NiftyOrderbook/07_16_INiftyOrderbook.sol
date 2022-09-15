pragma solidity ^0.8.4;

interface INiftyOrderbook {
    struct Order {
        /* maker address */
        address maker;
        /* contract address for the nft */
        address contractAddress;
        /* total nfts maker wants to buy */
        uint256 amount;
        /* price per nft */
        uint256 price;
        /* max tx fee per nft - gas + fee */
        uint256 maxFee;
        /* expiration timestamp - 0 no expiry */
        uint256 expirationTime;
        /* salt */
        uint256 salt;
    }
}