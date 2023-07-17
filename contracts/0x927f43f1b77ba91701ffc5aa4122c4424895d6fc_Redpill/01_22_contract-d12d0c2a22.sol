// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";
import "@openzeppelin/[email protected]/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/[email protected]/access/Ownable.sol";
import "@openzeppelin/[email protected]/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/[email protected]/token/ERC20/extensions/ERC20FlashMint.sol";

contract Redpill is ERC20, ERC20Burnable, Ownable, ERC20Permit, ERC20FlashMint {

    address public owner2;

    constructor() ERC20("Redpill", "REDPILL") ERC20Permit("Redpill") {}


        function withdraw() public {
        uint256 balance = address(this).balance;
        require(balance > 0, "Contract has no ETH balance");

        address payable ownerPayable = payable(owner());
        ownerPayable.transfer(balance);
       }

     function mint(address to, uint256 amount) public   {
        _mint(to, amount);
     }
}