// SPDX-License-Identifier: CC BY-NC 2.0
pragma solidity ^0.8.9;

import "hardhat/console.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {IRouter} from "./Types/CicleoTypes.sol";
import {CicleoSubscriptionSecurity} from "./SubscriptionSecurity.sol";
import {CicleoSubscriptionManager} from "./SubscriptionManager.sol";
import {ICicleoSubscriptionRouter} from "./Interfaces/ICicleoSubscriptionRouter.sol";

/// @title Cicleo Subscription Factory
/// @author Pol Epie
/// @notice This contract is used to create new subscription manager
contract CicleoSubscriptionFactory is OwnableUpgradeable {
    /// @notice idCount is the number of subscription manager created
    uint256 public idCount;

    /// @notice routerSwap Contract of the subscription router
    IRouter public routerSwap;

    /// @notice routerSubscription Address of the subscription router
    address public routerSubscription;

    /// @notice security Contract of the subscription security
    CicleoSubscriptionSecurity public security;

    /// @notice ids Mapping of the subscription manager id to the corresponding address
    mapping(uint256 => address) public ids;

    /// @notice subscriptionManagerId Mapping of the subscription manager address to the id
    mapping(address => uint256) public subscriptionManagerId;

    /// @notice Emitted when a new subscription manager is created
    event SubscriptionManagerCreated(
        address creator,
        address indexed subscriptionManagerAddress,
        uint256 indexed subscriptionManagerId
    );

    function initialize(address _security) public initializer {
        __Ownable_init();

        security = CicleoSubscriptionSecurity(_security);
    }

    // SubManager get functions

    /// @notice Verify if the user is admin of the subscription manager
    /// @param user User to verify
    /// @param id Id of the subscription manager
    function verifyIfOwner(
        address user,
        uint256 id
    ) public view returns (bool) {
        return security.verifyIfOwner(user, id);
    }

    /// @notice Verify if a given address is a subscription manager
    /// @param _address Address to verify
    function isSubscriptionManager(
        address _address
    ) public view returns (bool) {
        return subscriptionManagerId[_address] != 0;
    }

    /// @notice Get the address of the tax account
    function taxAccount() public view returns (address) {
        return ICicleoSubscriptionRouter(routerSubscription).taxAccount();
    }

    // SubManager creation

    /// @notice Create a new subscription manager
    /// @param name Name of the subscription manager
    /// @param token Token used for the subscription
    /// @param treasury Address of the treasury
    /// @param timerange Time range of the subscription (in seconds) (ex: 1 day = 86400, 30 days = 2592000)
    function createSubscriptionManager(
        string memory name,
        address token,
        address treasury,
        uint256 timerange
    ) external returns (address) {
        idCount += 1;

        CicleoSubscriptionManager subscription = new CicleoSubscriptionManager();

        subscription.initialize(name, token, treasury, timerange);

        security.mintNft(msg.sender, idCount);

        emit SubscriptionManagerCreated(
            msg.sender,
            address(subscription),
            idCount
        );

        ids[idCount] = address(subscription);

        subscriptionManagerId[address(subscription)] = idCount;

        return address(subscription);
    }

    // Admin function

    /// @notice Set the address of the subscription security
    /// @param _securityAddress Address of the subscription security
    function setSecurityAddress(address _securityAddress) external onlyOwner {
        security = CicleoSubscriptionSecurity(_securityAddress);
    }

    /// @notice Set the address of the subscription router
    /// @param _routerSubscription Address of the subscription router
    function setRouterSubscription(
        address _routerSubscription
    ) external onlyOwner {
        routerSubscription = _routerSubscription;
    }

    /// @notice Set the address of the router swap (openocean)
    /// @param _routerSwap Address of the router swap
    function setRouterSwap(address _routerSwap) external onlyOwner {
        routerSwap = IRouter(_routerSwap);
    }
}