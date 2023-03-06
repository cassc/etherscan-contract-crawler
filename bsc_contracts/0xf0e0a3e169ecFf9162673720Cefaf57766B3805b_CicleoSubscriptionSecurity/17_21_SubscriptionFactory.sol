// SPDX-License-Identifier: GPL-1.0-or-later
pragma solidity ^0.8.9;

import "hardhat/console.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {IRouter} from "./Types/CicleoTypes.sol";
import {CicleoSubscriptionSecurity} from "./SubscriptionSecurity.sol";
import {CicleoSubscriptionManager} from "./SubscriptionManager.sol";

contract CicleoSubscriptionFactory is OwnableUpgradeable {
    address public botAddress;

    uint256 public idCount;

    uint256 public taxPercent;
    address public taxAccount;

    IRouter public router;
    CicleoSubscriptionSecurity public security;

    mapping(uint256 => address) public ids;
    mapping(address => uint256) public subscriptionManagerId;

    event SubscriptionManagerCreated(
        address creator,
        address indexed subscriptionAddress
    );

    function initialize(
        address _botAddress,
        uint256 _taxPercent,
        address _taxAccount,
        address _router,
        address _security
    ) public initializer {
        __Ownable_init();

        botAddress = _botAddress;

        taxPercent = _taxPercent;
        taxAccount = _taxAccount;
        router = IRouter(_router);
        security = CicleoSubscriptionSecurity(_security);
    }

    /* SubManager get functions */

    function verifyIfOwner(
        address _user,
        uint256 _id
    ) public view returns (bool) {
        return security.verifyIfOwner(_user, _id);
    }

    function isSubscriptionManager(
        address _address
    ) public view returns (bool) {
        return subscriptionManagerId[_address] != 0;
    }

    /* SubManager creation */

    function createSubscriptionManager(
        string memory name,
        address token,
        address treasury
    ) external returns (address) {
        idCount += 1;
        
        CicleoSubscriptionManager subscription = new CicleoSubscriptionManager(
            address(this),
            name,
            token,
            treasury
        );

        security.mintNft(msg.sender, idCount);

        emit SubscriptionManagerCreated(msg.sender, address(subscription));

        ids[idCount] = address(subscription);

        subscriptionManagerId[address(subscription)] = idCount;

        return address(subscription);
    }

    /* Admin function */

    function setSecurityAddress(address _securityAddress) external onlyOwner {
        security = CicleoSubscriptionSecurity(_securityAddress);
    }

    function setBot(address _botAddress) external onlyOwner {
        botAddress = _botAddress;
    }

    function setTaxPercent(uint256 _taxPercent) external onlyOwner {
        taxPercent = _taxPercent;
    }

    function setTaxAccount(address _taxAccount) external onlyOwner {
        taxAccount = _taxAccount;
    }

    function setRouter(address _router) external onlyOwner {
        router = IRouter(_router);
    }
}