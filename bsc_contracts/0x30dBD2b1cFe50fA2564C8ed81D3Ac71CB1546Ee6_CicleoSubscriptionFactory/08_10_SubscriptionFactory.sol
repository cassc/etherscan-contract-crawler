//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "hardhat/console.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./SubscriptionManager.sol";

struct SubscriptionManagerStruct {
    uint256 id;
    string name;
    uint256 activeSub;
    string symbol;
}

contract CicleoSubscriptionFactory is OwnableUpgradeable {
    address public botAddress;

    uint256 public idCount;

    uint256 public taxPercent;
    address public taxAccount;

    IRouter public router;

    mapping(uint256 => address) public ids;
    mapping(address => uint256[]) public accessAllowed;
    mapping(address => bool) public isSubscriptionAddress;

    event SubscriptionManagerCreated(
        address creator,
        address indexed subscriptionAddress
    );

    function initialize(
        address _botAddress,
        uint256 _taxPercent,
        address _taxAccount,
        address _router
    ) public initializer {
        __Ownable_init();

        botAddress = _botAddress;

        taxPercent = _taxPercent;
        taxAccount = _taxAccount;
        router = IRouter(_router);
    }

    function createSubscriptionManager(
        string memory name,
        address token,
        address treasury
    ) external returns (address) {
        CicleoSubscriptionManager subscription = new CicleoSubscriptionManager(
            address(this),
            name,
            token,
            treasury
        );
        subscription.transferOwnership(msg.sender);

        emit SubscriptionManagerCreated(msg.sender, address(subscription));

        ids[idCount] = address(subscription);
        accessAllowed[msg.sender].push(idCount);
        idCount += 1;

        isSubscriptionAddress[address(subscription)] = true;

        return address(subscription);
    }

    function setBotAddress(address _botAddress) external onlyOwner {
        botAddress = _botAddress;
    }

    function setTaxPercent(uint256 _taxPercent) external onlyOwner {
        require(_taxPercent <= 1000, "Tax percent cannot be more than 1000");
        taxPercent = _taxPercent;
    }

    function setTaxAccount(address _taxAccount) external onlyOwner {
        taxAccount = _taxAccount;
    }

    function getName(uint256 _id) public view returns (string memory) {
        return CicleoSubscriptionManager(ids[_id]).name();
    }

    function getActiveSub(uint256 _id) public view returns (uint256) {
        return CicleoSubscriptionManager(ids[_id]).getActiveSubscriptionCount();
    }

    function getTokenSymbol(uint256 _id) public view returns (string memory) {
        return CicleoSubscriptionManager(ids[_id]).getSymbol();
    }

    function getSubscription(
        address user
    ) external view returns (SubscriptionManagerStruct[] memory) {
        SubscriptionManagerStruct[]
            memory callback = new SubscriptionManagerStruct[](
                accessAllowed[user].length
            );
        for (uint i = 0; i < accessAllowed[user].length; i++) {
            callback[i] = SubscriptionManagerStruct(
                accessAllowed[user][i],
                getName(accessAllowed[user][i]),
                getActiveSub(accessAllowed[user][i]),
                getTokenSymbol(accessAllowed[user][i])
            );
        }
        return callback;
    }
}