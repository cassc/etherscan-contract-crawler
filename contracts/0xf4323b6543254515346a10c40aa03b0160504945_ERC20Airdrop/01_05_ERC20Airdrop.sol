// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Import this file to use console.log
import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ERC20Airdrop is Ownable {

    IERC20 internal erc20Token;
    address internal erc20TokenHolder;

    // Initialize the airdrop contract
    constructor(
        address _erc20Token,                    // The token to airdrop
        address _tokenHolder                    // the address of the token holder whose tokens we are spending.
    ) public {

        // set up properties
        erc20Token = IERC20(_erc20Token);
        erc20TokenHolder = _tokenHolder;

    }

    /// @dev airdrop the token
    function airdropERC20 (
        address[] memory _recipients,
        uint256 _numRecipients,
        uint256 _amountToAirdropPerRecipient
    ) public onlyOwner() {

        // If the contract is the tokenholder, make sure the contract has sufficient balance
        if (erc20TokenHolder == address(this)) {
            require(
                erc20Token.balanceOf(address(this)) >= _numRecipients * _amountToAirdropPerRecipient,
                "ERC20AD0: Contract has insufficient funds"
            );
        }

        // if the contract is not the tokenholder, make sure the contract has sufficient allowance
        else {
            require(
                erc20Token.allowance(erc20TokenHolder, address(this)) >= _numRecipients * _amountToAirdropPerRecipient,
                "ERC20AD1: Contract has insufficient approval"
            );
        }

        // Do the airdrop
        for (uint256 i = 0; i < _numRecipients; i++) {
            bool success = erc20Token.transferFrom(
                erc20TokenHolder,
                _recipients[i],
                _amountToAirdropPerRecipient
            );
            if (!success) {
                console.log("Failed to transfer token to ", _recipients[i]);
            }
        }
    }

}