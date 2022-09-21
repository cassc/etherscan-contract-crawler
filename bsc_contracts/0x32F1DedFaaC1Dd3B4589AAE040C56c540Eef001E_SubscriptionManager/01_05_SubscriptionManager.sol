//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

contract SubscriptionManager is Ownable {
    event Payment(address user, uint8 subscrptionType, bool isYear);

    uint256[] public subscriptionPricePerMonth;
    uint256[] public subscriptionPricePerYear;
    IERC20 public token;
    address public treasury;
    address public bot;

    constructor () {
        subscriptionPricePerMonth = [0,0,20 ether,20 ether];
        subscriptionPricePerYear = [0,0,20 ether,20 ether];
    }

    function payFunction(uint8 subscrptionType, bool isYear) internal {
        require(subscrptionType == 2 || subscrptionType == 3, "Wrong sub type");
        address user = msg.sender;

        uint256 price;
        if (isYear) {
            price = subscriptionPricePerYear[subscrptionType];
        } else {
            price = subscriptionPricePerMonth[subscrptionType];
        }

        token.transferFrom(user, treasury, price);

        emit Payment(user, subscrptionType, isYear);
    }

    function subscriptionRenew(uint8 subscrptionType, bool isYear) external {
        require(msg.sender == bot, "Not allowed to");
        payFunction(subscrptionType, isYear);
    }

    function paymentForSmsPackage(bool isYear) external {
        payFunction(2, isYear);
    }

    function paymentForWhatsappPackage(bool isYear) external {
        payFunction(3, isYear);
    }

    function setToken(address _token) external onlyOwner {
        token = IERC20(_token);
    }

    function setTreasury(address _treasury) external onlyOwner {
        treasury = _treasury;
    }

    function setBot(address _bot) external onlyOwner {
        bot = _bot;
    }
}