// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/master/contracts/token/ERC20/IERC20.sol";
import "https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/master/contracts/utils/ReentrancyGuard.sol";
import "https://raw.githubusercontent.com/smartcontractkit/chainlink/develop/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/master/contracts/utils/Pausable.sol";
import "https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/master/contracts/token/ERC20/utils/SafeERC20.sol";

contract FeeManager {
    using SafeERC20 for IERC20;
    address public admin;
    address public owner;

    mapping(address => uint256) public collectedFees;

    event FeeDistributed(address indexed admin, address token, uint256 amount);
    event FeeWithdrawn(address indexed admin, address indexed user, address token, uint256 amount);

    constructor(address _admin) {
        require(_admin != address(0), "Invalid admin address");
        admin = _admin;
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Not authorized");
        _;
    }

    function updateAdmin(address newAdmin) external onlyAdmin {
        require(newAdmin != address(0), "Invalid admin address");
        admin = newAdmin;
    }

    function addFees(address token, uint256 amount) external onlyAdmin {
        // This function can be expanded with business logic as needed
        collectedFees[token] += amount;
        emit FeeDistributed(msg.sender, token, amount);
    }

    function withdrawFees(address token, uint256 amount, address recipient) external onlyAdmin {
        require(collectedFees[token] >= amount, "Not enough fees");
        require(recipient != address(0), "Cannot withdraw to the zero address");

        uint256 contractBalance = IERC20(token).balanceOf(address(this));
        require(contractBalance >= amount, "Insufficient contract balance");

        // Update the collected fees for the token
        collectedFees[token] -= amount;

        // Transfer the tokens to the recipient
        IERC20(token).safeTransfer(recipient, amount);

        emit FeeWithdrawn(msg.sender, recipient, token, amount);
    }

    function getTotalFees(address token) external view returns (uint256) {
        return collectedFees[token];
    }

    function withdrawTokens(address token, uint256 amount, address to) external onlyOwner {
        require(to != address(0), "Cannot withdraw to the zero address");
        uint256 balance = IERC20(token).balanceOf(address(this));
        require(balance >= amount, "Not enough tokens in the contract");

        IERC20(token).safeTransfer(to, amount);
    }
}