// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Amatik is ERC20,  Ownable{
    address public bankReserve;
    constructor(address owner_, address bankReserve_) ERC20("Amatik", "AMT") {
        require(owner_ != address(0), "Owner address can't be address zero");
        require(bankReserve_ != address(0), "BankReserve address can't be address zero");
        _mint(owner_, 2e8 * 1e18);
        transferOwnership(owner_);
        bankReserve = bankReserve_;
    }

    function burn() external onlyOwner{
        _burn(bankReserve, balanceOf(bankReserve));
    }
}