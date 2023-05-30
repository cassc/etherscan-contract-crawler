// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "openzeppelin/access/Ownable.sol";
import "openzeppelin/token/ERC20/extensions/draft-ERC20Permit.sol";

contract Xai is Ownable, ERC20Permit {
    string private constant _NAME = "XAI Stablecoin";
    string private constant _SYMBOL = "XAI";

    constructor() ERC20(_NAME, _SYMBOL) ERC20Permit(_NAME) {}

    /**
     * @dev Creates an amount of XAI and assigns it to the provided address.
     * It is meant to be called by a trusted controller contract.
     *
     * @param to Address that will receive the funds.
     * @param amount Amount of XAI to mint.
     */
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    /**
     * @dev Burns an amount of XAI from the sender.
     * Can be called by any XAI holder.
     *
     * @param amount Amount of XAI to burn.
     */
    function burn(uint256 amount) external {
        _burn(_msgSender(), amount);
    }
}