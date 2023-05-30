// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {ERC20Burnable} from "openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";

/// @title Wrapped ENaira
/// @author Mohamed Amine LEGHERABA for boom.market
/// @notice the wrapped enaira is implemented using OpenZepplin contracts as an ERC20 token 
/// @dev Inspired by the code generated on OpenZeppelin Wizard: https://wizard.openzeppelin.com/
/// @custom:security-contact [email protected]
contract WrappedENaira is ERC20, ERC20Burnable, Ownable {
    uint256 public initialAmount = 1300000000000; // 1.3 trillion (1 300 000 000 000)
    string public tokenName = "Wrapped eNaira";
    string public tokenSymbol = "WeNGN";

    constructor() ERC20(tokenName, tokenSymbol) {
        _mint(msg.sender, initialAmount * 10 ** decimals());
    }

    /// @notice Minting function to allow the owner to create any amount of tokens
    /// @dev Mohamed Amine LEGHERABA
    /// @param to the address that will receive the tokens
    /// @param amount the amount of tokens to create
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}