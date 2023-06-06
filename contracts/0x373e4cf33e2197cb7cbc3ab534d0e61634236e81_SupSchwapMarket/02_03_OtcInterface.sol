// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.13;

abstract contract OtcInterface {
    struct OfferInfo {
        uint              pay_amt;
        address           pay_gem;
        uint              buy_amt;
        address           buy_gem;
        address           owner;
        uint64            timestamp;
    }
    mapping (uint => OfferInfo) public offers;
    function getBestOffer(address, address) public virtual view returns (uint);
    function getWorseOffer(uint) public virtual view returns (uint);
}