// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./SubscriptionsManager.sol";

contract SubscriptionsManagerFactory is Ownable {
    event NewSubscriptionsManagerDeployed(
        address indexed managerAddress,
        string name,
        string indexed symbol,
        address indexed owner_,
        uint16 adminFee_
    );

    function deployNewSubscriptionsManager(
        string memory name,
        string memory symbol,
        address owner_,
        uint16 adminFee_
    ) external onlyOwner {
        SubscriptionsManager subscriptionsManager = new SubscriptionsManager(
            name,
            symbol,
            owner_,
            owner(),
            adminFee_
        );

        emit NewSubscriptionsManagerDeployed(
            address(subscriptionsManager),
            name,
            symbol,
            owner_,
            adminFee_
        );
    }
}