//SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title A token which has a defined max amount which can be minted by owner
/// @author Brendan Duhamel (Myria)

contract MyriaToken is ERC20, Ownable {
    // 18 decimals
    uint256 public MAX_SUPPLY = 50_000_000_000 * (10**18);
    
    constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) {}

    /// @dev Mints some new tokens, only callable by owner
    /// @param amount The amount of new tokens to be minted
    function mint(uint256 amount) external onlyOwner {
        require(MAX_SUPPLY >= (totalSupply()+amount), "Cannot exceed max supply");
        _mint(_msgSender(), amount);
    }

    /// @dev Burn some tokens by sending them to 0 address
    /// @param amount Number of tokens to be burned
    function burn(uint amount) external {
        _burn(_msgSender(), amount);
    }
}