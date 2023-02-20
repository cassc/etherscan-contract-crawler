//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title BLUMER
 * @author  BLUMER
 * @notice  BLUMER token
 */
contract BLUMER is ERC20 {
    /**
     *  @dev Constructor of the BLUMER token
     * @param name  name of the token
     * @param symbol  symbol of the token
     * @param initialSupply  initial supply of the token
     */
    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply
    ) ERC20(name, symbol) {
        _mint(msg.sender, initialSupply);
    }
}