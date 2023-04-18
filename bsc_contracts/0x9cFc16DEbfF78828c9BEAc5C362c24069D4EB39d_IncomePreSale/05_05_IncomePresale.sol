// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/*
 * Pre Sale Contract
 */
contract IncomePreSale is Ownable {
    using SafeMath for uint256;

    address public saleToken;
    address public marketingWallet;
    uint256 public tokensPerUnit;
    uint256 public maxPerWallet;
    bool public limitContributions;

    mapping(address => uint256) public userContribution;

    constructor() Ownable() {
        saleToken = 0x3561b55f34FF9e0d905974af758051eac46b4160;
        marketingWallet = 0xF007f7382850A8846902bA1217A3877834158B77;
        tokensPerUnit = 6200; // SET AS RAW NUMBER, NOT AS WEI
        maxPerWallet = 100 * (10 ** 18);
        limitContributions = false;
    }

    receive() external payable {
        processContribution(msg.sender, msg.value);
        payable(marketingWallet).transfer(address(this).balance);
    }

    /*
     * Admin Functions
     */
    function returnUnusedTokens() external onlyOwner {
        IERC20(saleToken).transfer(
            msg.sender,
            IERC20(saleToken).balanceOf(address(this))
        );
    }

    function collectSaleFunds() external onlyOwner {
        payable(marketingWallet).transfer(address(this).balance);
    }

    function removeWrongTokens(address token_) external onlyOwner {
        IERC20(token_).transfer(
            msg.sender,
            IERC20(token_).balanceOf(address(this))
        );
    }

    /*
     * Basic Contract Functions
     */
    function processContribution(address wallet_, uint256 amount_) internal {
        require(
            userContribution[wallet_].add(amount_) <= maxPerWallet ||
                maxPerWallet == 0,
            "Exceeds maximum contribution"
        );
        require(
            amount_.mul(tokensPerUnit) <=
                IERC20(saleToken).balanceOf(address(this)),
            "Not enough tokens remain"
        );
        require(
            userContribution[wallet_] == 0 || limitContributions == false,
            "Only one contribution per wallet"
        );

        bool tokensSent = IERC20(saleToken).transfer(
            msg.sender,
            amount_.mul(tokensPerUnit)
        );

        if (tokensSent) {
            userContribution[wallet_] += amount_;
        }
    }

    function updateSaleToken(address _saleToken) external onlyOwner {
        saleToken = _saleToken;
    }

    function updateTokenPerUnit(uint256 _tokensPerUnit) external onlyOwner {
        tokensPerUnit = _tokensPerUnit;
    }
}