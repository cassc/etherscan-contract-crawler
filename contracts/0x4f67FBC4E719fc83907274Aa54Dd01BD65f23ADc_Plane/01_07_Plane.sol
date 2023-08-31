// SPDX-License-Identifier: MIT

/*
██████╗░██╗░░░░░░█████╗░███╗░░██╗███████╗
██╔══██╗██║░░░░░██╔══██╗████╗░██║██╔════╝
██████╔╝██║░░░░░███████║██╔██╗██║█████╗░░
██╔═══╝░██║░░░░░██╔══██║██║╚████║██╔══╝░░
██║░░░░░███████╗██║░░██║██║░╚███║███████╗
╚═╝░░░░░╚══════╝╚═╝░░╚═╝╚═╝░░╚══╝╚══════╝
*/

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Plane is ERC20, ERC20Burnable, Ownable {
    constructor(
        address[] memory recipients,
        uint256[] memory percentages
    ) ERC20("PLANE", "PLAN") {
        uint256 initialSupply = 100000000 * 10 ** decimals();
        _mint(msg.sender, initialSupply);
        _distribution(recipients, percentages);
    }

    function _distribution(
        address[] memory recipients,
        uint256[] memory percentages
    ) internal {
        require(recipients.length == percentages.length, "Mismatched arrays");

        uint256 totalSupply = totalSupply();
        uint256 totalDistributed = 0;

        for (uint256 i = 0; i < recipients.length - 1; i++) {
            uint256 amount = (totalSupply * percentages[i]) / 10000; // Calculate the amount based on the percentage
            totalDistributed += amount;
            _transfer(owner(), recipients[i], amount);
        }

        // For the last recipient, transfer the remaining balance
        uint256 remainingAmount = totalSupply - totalDistributed;
        _transfer(owner(), recipients[recipients.length - 1], remainingAmount);
    }
}