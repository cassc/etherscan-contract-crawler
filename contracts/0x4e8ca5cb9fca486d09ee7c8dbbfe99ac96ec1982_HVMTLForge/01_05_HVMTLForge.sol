// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./lib/Operator.sol";

error ForgePurchasesNotEnabled();

contract HVMTLForge is Operator {
    bool public isForgePurchasesEnabled = false;
    address public immutable apeCoinContract;

    mapping(address => uint256) totalPurchased;

    event ForgePurchase(
        address indexed playerAddress,
        uint256 indexed amountApePurchased
    );

    constructor(address _apeCoinContract, address _operator)
        Operator(_operator)
    {
        apeCoinContract = _apeCoinContract;
    }

    /**
     * @notice purchase gears with apecoin
     * @param quantity the amount of apecoin to purchase
     */
    function purchase(uint256 quantity) external {
        if (!isForgePurchasesEnabled) revert ForgePurchasesNotEnabled();

        IERC20(apeCoinContract).transferFrom(
            _msgSender(),
            address(this),
            quantity * 1 ether
        );

        totalPurchased[_msgSender()] += quantity;
        emit ForgePurchase(_msgSender(), quantity);
    }

    /**
     * @notice get the total purchases for a player address
     * @param playerAddress the address of the player
     * @return uint256 total number of purchases
     */
    function getPurchasesByPlayer(address playerAddress)
        external
        view
        returns (uint256)
    {
        return totalPurchased[playerAddress];
    }

    // Operator functions

    /**
     * @notice set the state of forge purchases
     * @param isEnabled the state of forge purchases
     */
    function setIsForgePurchasesEnabled(bool isEnabled) external onlyOperator {
        isForgePurchasesEnabled = isEnabled;
    }

    /**
     * @notice withdraw APE erc-20 tokens from the contract
     */
    function withdrawAPE() external onlyOperator {
        uint256 balance = IERC20(apeCoinContract).balanceOf(address(this));
        if (balance > 0) {
            IERC20(apeCoinContract).transfer(operator, balance);
        }
    }

    /**
     * @notice withdraw any erc-20 tokens from the contract
     * @param coinContract the erc-20 contract address
     */
    function withdraw(address coinContract) external onlyOperator {
        uint256 balance = IERC20(coinContract).balanceOf(address(this));
        if (balance > 0) {
            IERC20(coinContract).transfer(operator, balance);
        }
    }
}