// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Snapshot.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BaseOfferToken is ERC20Snapshot, Ownable {
    using SafeMath for uint256;

    // A fuse to disable the exchangeBalance function
    bool internal bDisabledExchangeBalance;

    /**
     * @dev Liqi Offer Token
     */
    constructor(string memory _name, string memory _symbol)
        public
        ERC20(_name, _symbol)
    {}

    /**
     * @dev Disables the exchangeBalance function
     */
    function disableExchangeBalance() public onlyOwner {
        require(!bDisabledExchangeBalance, "Exchange balance is already disabled");

        bDisabledExchangeBalance = true;
    }

    /**
     * @dev Exchanges the funds of one address to another
     */
    function exchangeBalance(address _from, address _to) public onlyOwner {
        // check if the function is disabled
        require(!bDisabledExchangeBalance, "Exchange balance has been disabled");
        // simple checks for empty addresses
        require(_from != address(0), "Transaction from 0x");
        require(_to != address(0), "Transaction to 0x");

        // get current balance of _from address
        uint256 amount = balanceOf(_from);

        // check if there's balance to transfer
        require(amount != 0, "Balance is 0");

        // transfer balance to new address
        _transfer(_from, _to, amount);
    }
}