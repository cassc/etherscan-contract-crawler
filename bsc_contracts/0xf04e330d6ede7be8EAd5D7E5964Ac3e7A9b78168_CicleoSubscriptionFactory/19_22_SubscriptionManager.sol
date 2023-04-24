// SPDX-License-Identifier: CC BY-NC 2.0
pragma solidity ^0.8.9;

import "hardhat/console.sol";
import "./Interfaces/IERC20.sol";
import {SwapDescription, SubscriptionStruct, UserData, IRouter, IOpenOceanCaller} from "./Types/CicleoTypes.sol";
import {CicleoSubscriptionFactory} from "./SubscriptionFactory.sol";

/// @title Cicleo Subscription Manager
/// @author Pol Epie
/// @notice This contract is used to manage subscription payments
contract CicleoSubscriptionManager {
    /// @notice users Mapping of the user address to the corresponding user data
    mapping(address => UserData) public users;

    /// @notice token Token used for the subscription
    IERC20 public token;

    /// @notice factory Address of the subscription factory
    CicleoSubscriptionFactory public factory;

    /// @notice name Name of the subscription
    string public name;

    /// @notice treasury Address of the treasury
    address public treasury;

    /// @notice subscriptionNumber Count of subscriptions
    uint256 public subscriptionNumber;

    /// @notice subscriptionDuration Duration of the subscription in seconds
    uint256 public subscriptionDuration;

    /// @notice Event when a user change his subscription limit
    event EditSubscriptionLimit(
        address indexed user,
        uint256 amountMaxPerPeriod
    );

    /// @notice Event when a user subscription state is changed (after a payment or via an admin)
    event UserEdited(
        address indexed user,
        uint256 indexed subscriptionId,
        uint256 endDate
    );

    /// @notice Event when a user cancels / stop his subscription
    event Cancel(address indexed user);

    /// @notice Event when a user subscription is edited
    event SubscriptionEdited(
        address indexed user,
        uint256 indexed subscriptionId,
        uint256 price,
        bool isActive
    );

    /// @notice Verify if the user is admin of the subscription manager
    modifier onlyOwner() {
        require(
            factory.verifyIfOwner(
                msg.sender,
                factory.subscriptionManagerId(address(this))
            ),
            "Not allowed to"
        );
        _;
    }

    modifier onlyRouter() {
        require(msg.sender == factory.routerSubscription(), "Not allowed to");
        _;
    }

    constructor() {
        factory = CicleoSubscriptionFactory(msg.sender);
    }

    /// @notice Initialize a subscription manager when created (called by the factory)
    /// @param _name Name of the subscription
    /// @param _token Token used for the subscription
    /// @param _treasury Address of the treasury
    /// @param _subscriptionDuration Duration of the subscription in seconds
    function initialize(
        string memory _name,
        address _token,
        address _treasury,
        uint256 _subscriptionDuration
    ) external {
        require(msg.sender == address(factory), "Not allowed to");

        name = _name;
        token = IERC20(_token);
        treasury = _treasury;
        subscriptionDuration = _subscriptionDuration;
    }

    /// @notice Edit the subscription limit
    /// @param amountMaxPerPeriod New subscription price limit per period in the submanager token
    function changeSubscriptionLimit(uint256 amountMaxPerPeriod) external {
        users[msg.sender].subscriptionLimit = amountMaxPerPeriod;

        emit EditSubscriptionLimit(msg.sender, amountMaxPerPeriod);
    }

    /// @notice Function to pay subscription with submanager token
    /// @param user User to pay the subscription
    /// @param subscriptionId Id of the subscription
    /// @param price Price of the subscription
    /// @param endDate End date of the subscription
    function payFunctionWithSubToken(
        address user,
        uint8 subscriptionId,
        uint256 price,
        uint256 endDate
    ) external {
        address routerSubscription = factory.routerSubscription();
        require(msg.sender == routerSubscription, "Not allowed to");

        require(users[user].canceled == false, "Subscription is canceled");

        require(
            users[user].lastPayment < block.timestamp - subscriptionDuration,
            "You cannot pay twice in the same period"
        );

        //Verify subscription limit
        require(
            users[user].subscriptionLimit >= price,
            "You need to approve our contract to spend this amount of tokens"
        );

        uint256 balanceBefore = token.balanceOf(routerSubscription);

        token.transferFrom(user, routerSubscription, price);

        //Verify if the token have a transfer fees or if the swap goes okay
        uint256 balanceAfter = token.balanceOf(routerSubscription);
        require(
            balanceAfter - balanceBefore >= price,
            "The token have a transfer fee"
        );

        //Save subscription info

        users[user].subscriptionEndDate = endDate;
        users[user].subscriptionId = subscriptionId;
        users[user].lastPayment = block.timestamp;
        users[user].canceled = false;
    }

    /// @notice Function to pay subscription with swap (OpenOcean)
    /// @param user User to pay the subscription
    /// @param executor Executor of the swap (OpenOcean)
    /// @param desc Description of the swap (OpenOcean)
    /// @param calls Calls of the swap (OpenOcean)
    /// @param subscriptionId Id of the subscription
    /// @param price Price of the subscription
    /// @param endDate End date of the subscription
    function payFunctionWithSwap(
        address user,
        IOpenOceanCaller executor,
        SwapDescription memory desc,
        IOpenOceanCaller.CallDescription[] calldata calls,
        uint8 subscriptionId,
        uint256 price,
        uint256 endDate
    ) external {
        address routerSubscription = factory.routerSubscription();
        require(msg.sender == routerSubscription, "Not allowed to");

        require(users[user].canceled == false, "Subscription is canceled");

        require(
            users[user].lastPayment < block.timestamp - subscriptionDuration,
            "You cannot pay twice in the same period"
        );

        //Verify subscription limit
        require(
            users[user].subscriptionLimit >= price,
            "You need to approve our contract to spend this amount of tokens"
        );

        IRouter routerSwap = factory.routerSwap();

        //OpenOcean swap
        desc.minReturnAmount = price;

        uint256 balanceBefore = token.balanceOf(address(this));

        IERC20(desc.srcToken).transferFrom(user, address(this), desc.amount);
        IERC20(desc.srcToken).approve(address(routerSwap), desc.amount);

        routerSwap.swap(executor, desc, calls);

        //Verify if the token have a transfer fees or if the swap goes okay
        uint256 balanceAfter = token.balanceOf(address(this));
        require(balanceAfter - balanceBefore >= price, "Swap failed");

        token.transfer(routerSubscription, balanceAfter);

        //Save subscription info

        users[user].subscriptionEndDate = endDate;
        users[user].subscriptionId = subscriptionId;
        users[user].lastPayment = block.timestamp;
        users[user].canceled = false;
    }

    /// @notice Function to cancel / stop subscription
    function cancel() external {
        users[msg.sender].canceled = true;

        emit Cancel(msg.sender);
    }

    //Get functions

    /// @notice Return the subscription status of a user
    /// @param user User to get the subscription status
    /// @return subscriptionId Id of the subscription (0 mean no subscription and 255 mean dynamic subscription)
    /// @return isActive If the subscription is currently active
    function getUserSubscriptionStatus(
        address user
    ) public view returns (uint8 subscriptionId, bool isActive) {
        UserData memory userData = users[user];
        return (
            userData.subscriptionId,
            userData.subscriptionEndDate > block.timestamp
        );
    }

    /// @notice Return the subscription id of a user
    /// @param user User to get the subscription id
    /// @return subscriptionId Id of the subscription (0 mean no subscription and 255 mean dynamic subscription)
    function getUserSubscriptionId(
        address user
    ) external view returns (uint8 subscriptionId) {
        UserData memory userData = users[user];
        return userData.subscriptionId;
    }

    /// @notice Return the token address of the submanager
    function tokenAddress() external view returns (address) {
        return address(token);
    }

    /// @notice Return the token decimals of the submanager
    function tokenDecimals() external view returns (uint8) {
        return token.decimals();
    }

    /// @notice Return the token symbol of the submanager
    function tokenSymbol() external view returns (string memory) {
        return token.symbol();
    }

    //Admin functions

    /// @notice Edit the subscription manager name
    /// @param _name New name of the subscription manager
    function setName(string memory _name) external {
        require(msg.sender == factory.routerSubscription(), "Not allowed to");
        name = _name;
    }

    /// @notice Edit the treasury address
    /// @param _treasury New treasury address
    function setTreasury(address _treasury) external {
        require(msg.sender == factory.routerSubscription(), "Not allowed to");
        treasury = _treasury;
    }

    /// @notice Edit the token address
    /// @param _token New Token address
    function setToken(address _token) external {
        require(msg.sender == factory.routerSubscription(), "Not allowed to");
        token = IERC20(_token);
    }

    /// @notice Edit the state of a user
    /// @param user User to edit
    /// @param subscriptionEndDate New subscription end date (timestamp unix seconds)
    /// @param subscriptionId New subscription id
    function editAccount(
        address user,
        uint256 subscriptionEndDate,
        uint8 subscriptionId
    ) external {
        require(msg.sender == factory.routerSubscription(), "Not allowed to");

        UserData memory _user = users[user];

        users[user] = UserData(
            subscriptionEndDate,
            subscriptionId,
            _user.subscriptionLimit,
            _user.lastPayment,
            _user.canceled
        );
    }

    /// @notice Function to change subscription type and pay the difference for the actual period
    /// @param user User to edit
    /// @param oldPrice Price of the old subscription
    /// @param newPrice Price of the new subscription
    /// @param subscriptionId New subscription id
    function changeSubscription(
        address user,
        uint256 oldPrice,
        uint256 newPrice,
        uint8 subscriptionId
    ) external returns (uint256) {
        address routerSubscription = factory.routerSubscription();
        require(msg.sender == routerSubscription, "Not allowed to");

        UserData memory _user = users[user];

        if (newPrice > oldPrice) {
            // Compute the price to be paid to regulate

            uint256 priceAdjusted = getAmountChangeSubscription(
                user,
                oldPrice,
                newPrice
            );

            token.transferFrom(user, routerSubscription, priceAdjusted);
        }

        //Change the id of subscription
        users[user] = UserData(
            _user.subscriptionEndDate,
            subscriptionId,
            _user.subscriptionLimit,
            _user.lastPayment,
            _user.canceled
        );

        return newPrice > oldPrice ? (newPrice - oldPrice) : 0;
    }

    function getAmountChangeSubscription(
        address user,
        uint256 oldPrice,
        uint256 newPrice
    ) public view returns (uint256) {
        UserData memory _user = users[user];

        uint256 currentTime = block.timestamp; 
        uint256 timeToNextPayment = _user.subscriptionEndDate;

        uint256 oldPriceAdjusted = (oldPrice *
            (subscriptionDuration - (timeToNextPayment - currentTime))) /
            subscriptionDuration;

        uint256 newPriceAdjusted = (newPrice *
            (timeToNextPayment - currentTime)) / subscriptionDuration;

        return newPriceAdjusted - oldPriceAdjusted;
    }

    /// @notice Delete the submanager
    function deleteSubManager() external onlyOwner {
        factory.security().deleteSubManager();
        selfdestruct(payable(factory.taxAccount()));
    }
}