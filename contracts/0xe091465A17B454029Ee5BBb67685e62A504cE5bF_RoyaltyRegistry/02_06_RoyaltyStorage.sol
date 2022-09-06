// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract RoyaltyStorage is OwnableUpgradeable {
    struct RoyaltySet {
        bool isSet;
        uint96 royaltyRateForCollection;
        address royaltyReceiver;
    }

    /// @dev storing royalty amount percentages for particular collection.
    mapping(address => RoyaltySet) public royaltiesSet;

    /// @dev default royalty percentage;
    uint96 public defaultRoyaltyRatePercentage;

    /// @dev receiver address of royalty.
    address public receiver;

    /// @dev model factory address.
    address public modelFactory;

    uint96 public constant MAX_RATE_ROYALTY = 1000;
}