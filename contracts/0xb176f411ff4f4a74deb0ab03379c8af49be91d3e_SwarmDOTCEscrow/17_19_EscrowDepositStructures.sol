//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.17;

/**
 * @dev dOTC Order stucture
 * @author Swarm
 */
struct OfferDeposit {
    uint256 offerId;
    address maker;
    uint256 amountDeposited;
    bool isFrozen;
}