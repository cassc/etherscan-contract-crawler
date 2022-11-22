// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDistribution {
    struct Initial {
        address owner;
        uint256 commissionPayment;
        address creator;
        uint256 royaltyPayment;
        address master;
        uint256 masterPayment;
        address l1;
        uint256 l1Payment;
        address l2;
        uint256 l2Payment;
        address seller;
        uint256 sellerPayment;
    }

    struct Sub {
        address owner;
        uint256 commissionPayment;
        address seller;
        uint256 sellerPayment;
    }

    struct KOL {
        address owner;
        uint256 commissionPayment;
        address creator;
        uint256 royaltyPayment;
        address master;
        uint256 masterPayment;
        address kol;
        uint256 kolPayment;
        address seller;
        uint256 sellerPayment;
    }
}