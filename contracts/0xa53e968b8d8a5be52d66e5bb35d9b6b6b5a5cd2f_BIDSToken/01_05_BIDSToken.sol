// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract BIDSToken is ERC20 {
    /**
     * @dev Constructor that mints tokens to the treasury address.
     * @param _treasury The address of the treasury.
     */
    constructor(address _treasury) ERC20("BIDSHOP", "BIDS") {
        _mint(_treasury, 1000000000000000000000000000);
    }

    /**
     * @dev Burns a specific amount of tokens.
     * @param _amount The amount of token to be burned.
     */
    function burn(uint256 _amount) external {
        _burn(msg.sender, _amount);
    }
}