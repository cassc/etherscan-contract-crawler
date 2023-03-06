// SPDX-License-Identifier: GPL-1.0-or-later
pragma solidity ^0.8.9;

import "hardhat/console.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SubscriptionStruct, UserData, SubscriptionManagerStruct, MinimifiedSubscriptionManagerStruct} from "./Types/CicleoTypes.sol";
import {CicleoSubscriptionSecurity} from "./SubscriptionSecurity.sol";
import {CicleoSubscriptionFactory} from "./SubscriptionFactory.sol";
import {CicleoSubscriptionManager} from "./SubscriptionFactory.sol";

contract CicleoSubscriptionRouter is OwnableUpgradeable {
    CicleoSubscriptionSecurity public security;
    CicleoSubscriptionFactory public factory;

    function initialize(address _factory) public initializer {
        __Ownable_init();

        factory = CicleoSubscriptionFactory(_factory);
        security = CicleoSubscriptionSecurity(factory.security());
    }

    function getSubscriptionsManager(
        address user
    ) external view returns (MinimifiedSubscriptionManagerStruct[] memory) {
        uint256[] memory ids = security.getSubManagerList(user);

        MinimifiedSubscriptionManagerStruct[]
            memory subManagers = new MinimifiedSubscriptionManagerStruct[](
                ids.length
            );

        for (uint256 i = 0; i < ids.length; i++) {
            CicleoSubscriptionManager subManager = CicleoSubscriptionManager(
                factory.ids(ids[i])
            );

            subManagers[i] = MinimifiedSubscriptionManagerStruct(
                ids[i],
                subManager.name(),
                subManager.tokenSymbol(),
                subManager.getActiveSubscriptionCount()
            );
        }

        return subManagers;
    }

    function getSubscriptionManager(
        uint256 id
    ) external view returns (SubscriptionManagerStruct memory) {
        CicleoSubscriptionManager subManager = CicleoSubscriptionManager(
            factory.ids(id)
        );

        return
            SubscriptionManagerStruct(
                id,
                subManager.name(),
                subManager.tokenAddress(),
                subManager.tokenSymbol(),
                subManager.tokenDecimals(),
                subManager.getActiveSubscriptionCount(),
                subManager.treasury(),
                subManager.getSubscriptions(),
                security.getOwnersBySubmanagerId(id)
            );
    }


    /* Admin function */

    function setFactory(address _factory) external onlyOwner {
        factory = CicleoSubscriptionFactory(_factory);
    }

    function setSecurity(address _security) external onlyOwner {
        security = CicleoSubscriptionSecurity(_security);
    }
}