//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/finance/PaymentSplitter.sol";

contract LumensSplitter is PaymentSplitter {
    //The below addresses are for example purposes only. Please modify them.
    address[] private payees = [
        0xDbD10Ff27EA8c4d8ea6795397996361862091410,
        0x38198ee928400Cd81ED4B72Aa0c550eF1c9ebE28,
        0x78F2268fEe6dd5ab3e30Ef1F040C62777b5DF42e,
        0x8c540BFb73D39CcCb59A2d48907091C19F191F55,
        0x2f508BE8Ac24d694b796411B35330aaB7c40E913,
        0xa16231D4DA9d49968D2191328102F6731Ef78FCA,
        0x30d6B3497e967B72013e921aAf5d5ee9915B1010,
        0x2B11D45ea9f7d133B7b3deDd5fd884cF6385CA7B
    ];

    //The below percentages are for example purposes only. Please modify them.
    uint256[] private payeesShares = [100, 100, 100, 100, 10, 10, 15, 565];

    constructor() PaymentSplitter(payees, payeesShares) {}

    function pendingPayment(address account) public view returns (uint256) {
        return ((address(this).balance + totalReleased()) * shares(account)) / totalShares() - released(account);
    }
}