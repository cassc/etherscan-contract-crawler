// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract VAULT is Ownable {
    /// @dev event to track deposits
    event Withdrawal(uint amount, uint when);

    /// @dev event deposit
    event EventDeposit(uint amount, uint when, string idUser, address user);

    IERC20 public token;

    constructor(address _token) {
        token = IERC20(_token);
    }

    /// @dev  deposit tokens into the vault
    function deposit(uint256 _amount, string memory _idUser) external {
        /// @dev Transfer the token to the contract
        require(
            _amount > 0,
            "Deposit: Specify an amount of token greater than zero"
        );

        /// @dev  Check that the user's token balance is enough to do the swap
        uint256 userBalance = token.balanceOf(_msgSender());
        require(
            userBalance >= _amount,
            "Deposit: Your balance is lower than the amount of tokens you want to sell"
        );

        /// @dev allowace check
        uint256 allowance = token.allowance(_msgSender(), address(this));
        require(
            allowance >= _amount,
            "Deposit: You need to approve the contract to spend your tokens"
        );

        token.transferFrom(_msgSender(), address(this), _amount);

        emit EventDeposit(_amount, block.timestamp, _idUser, _msgSender());
    }

    /// @dev Allow the owner of the contract to withdraw
    function withdrawToken(uint256 _amount) external onlyOwner {
        require(
            token.transfer(_msgSender(), _amount),
            "Withdraw Token: Failed to transfer token to Onwer"
        );

        emit Withdrawal(_amount, block.timestamp);
    }
}