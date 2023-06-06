// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./KinkToken.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/// @custom:security-contact [email protected]
contract KinkTokenVending is Initializable, OwnableUpgradeable {
    AggregatorV3Interface internal priceFeed;
    KinkToken private kinkToken;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(KinkToken _kinkToken) {
        kinkToken = _kinkToken;
        priceFeed = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
        _transferOwnership(msg.sender);

        // Chainlink ETH-USD oracle contract
    }

    function buyTokens(uint256 amount) public payable {
        // amount is in the number of token * 10 ^ decimals to support decimals
        uint256 ethPrice = getEthPrice();
        require(amount >= 25 * 10 ** kinkToken.decimals(), "Needs to purchase more than 25 tokens at a time");
        // Check that >= 25 tokens are bought
        require(msg.value == amount * 10 ** getOracleDec() / ethPrice, "Incorrect amount sent");
        // Check that the correct amount of ETH is sent for the requested amount of tokens

        // kinkToken.mint(msg.sender,  amount); // Mint the KINK tokens and transfer them to the buyer's address
        bool success = kinkToken.transfer(msg.sender, amount);
        require(success, "Failed to transfer KINK tokens");
    }

    function getTokenDec() public view returns (uint8) {
        uint8 decimals = kinkToken.decimals();
        // For localhost only
        // uint8 decimals = 8
        return decimals;
    }

    function getEthPrice() public view returns (uint256) {
        (,int price,,,) = priceFeed.latestRoundData();
        require(price >= 0, "Incorrect Chainlink Oracle Price Feed");
        // For localhost only
        // int price = int(1900 * 10 ** 8);
        return uint256(price);
    }

     function getOracleDec() public view returns (uint8) {
        uint8 decimals = priceFeed.decimals();
        return decimals;
    }

    // Withdraw ETH from the contract
    function withdraw(uint256 amount) external onlyOwner {
        payable(msg.sender).transfer(amount);
    }
}