//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

contract SubscriptionManager is Ownable {
    event Payment(address indexed user, uint8 subscrptionType);

    uint256[] public subscriptionPrice;
    IERC20 public token;
    address public treasury;
    address public bot;

    constructor () {
        subscriptionPrice = [30 ether,150 ether,300 ether];
    }

    function payFunction(address user, uint8 subscrptionType) internal {
        require(subscrptionType >= 1 && subscrptionType <= subscriptionPrice.length, "Wrong sub type");

        uint256 price = subscriptionPrice[subscrptionType];

        token.transferFrom(user, treasury, price);

        emit Payment(user, subscrptionType);
    }

    function subscriptionRenew(address user, uint8 subscrptionType) external {
        require(msg.sender == bot, "Not allowed to");
        payFunction(user, subscrptionType);
    }

    function paymentForBronzePackage() external {
        payFunction(msg.sender, 1);
    }

    function paymentForSilverPackage() external {
        payFunction(msg.sender, 2);
    }

    function paymentForGoldPackage() external {
        payFunction(msg.sender, 3);
    }

    function setToken(address _token) external onlyOwner {
        token = IERC20(_token);
    }

    function setToken(uint256[] memory _subscriptionPrice) external onlyOwner {
        subscriptionPrice = _subscriptionPrice;
    }

    function setTreasury(address _treasury) external onlyOwner {
        treasury = _treasury;
    }

    function setBot(address _bot) external onlyOwner {
        bot = _bot;
    }
}