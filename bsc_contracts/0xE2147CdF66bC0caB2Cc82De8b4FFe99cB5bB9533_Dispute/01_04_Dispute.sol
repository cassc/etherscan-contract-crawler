// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./DefxInterfaces.sol";
import "./DefxHelpers.sol";

contract Dispute {
    using SafeMath for uint256;

    address public resolver;
    address public factory;

    constructor(address _factory) {
        resolver = msg.sender;
        factory = _factory;
    }

    modifier onlyResolver() {
        require(msg.sender == resolver, "FORBIDDEN");
        _;
    }

    function setFactory(address _factory) external onlyResolver {
        factory = _factory;
    }

    function incrementAccountStat(address account, bool isFailed) internal {
        IDefxStat stats = IDefxStat(IDefxFactory(factory).statAddress());
        stats.incrementAccountStat(account, isFailed);
    }

    function incrementAccountStat(address a, address b) internal {
        IDefxStat stats = IDefxStat(IDefxFactory(factory).statAddress());
        stats.incrementFailedDeal(a, b);
    }

    function closeDispute(
        address pairAddress,
        address buyer,
        address seller,
        uint8 resolveStatus
    ) external onlyResolver {
        IDefxPair pair = IDefxPair(pairAddress);
        Deal memory deal = pair.getDeal(buyer, seller);
        pair.closeDispute(buyer, seller);
        address cryptoAddress = pair.cryptoAddress();

        bool isResolverReward = true;
        // buyer wins
        if (resolveStatus == 0) {
            TransferHelper.safeTransfer(cryptoAddress, buyer, deal.collateral.add(deal.amountCrypto));
            incrementAccountStat(buyer, false);
            incrementAccountStat(seller, true);
        }
        // seller wins
        else if (resolveStatus == 1) {
            TransferHelper.safeTransfer(cryptoAddress, seller, deal.collateral.add(deal.amountCrypto));
            incrementAccountStat(buyer, true);
            incrementAccountStat(seller, false);
        }
        // cancel
        else {
            TransferHelper.safeTransfer(cryptoAddress, seller, deal.collateral.add(deal.amountCrypto));
            TransferHelper.safeTransfer(cryptoAddress, seller, deal.collateral);
            isResolverReward = false;
            incrementAccountStat(buyer, seller);
        }

        if (isResolverReward) {
            TransferHelper.safeTransfer(cryptoAddress, msg.sender, deal.collateral);
        }
    }
}