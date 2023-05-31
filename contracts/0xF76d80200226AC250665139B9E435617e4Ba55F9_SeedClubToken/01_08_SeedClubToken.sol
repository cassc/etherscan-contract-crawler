// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";

/// @title Seed Club's official token's contract.
contract SeedClubToken is ERC20, Ownable, Multicall {
    constructor() ERC20("Seed Club", "CLUB") {
        _mint(msg.sender, 10000000 * 10**decimals());
    }

    /// @notice Mint an amount of tokens to an address. Callable only by the owner.
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}