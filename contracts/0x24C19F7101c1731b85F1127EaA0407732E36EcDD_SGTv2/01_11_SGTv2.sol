// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

// Inherit permit to allow a permit signed approval for gas savings
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
// Token needs to be burnable to allow the voteEscrow to burn self tokens as early withdraw penalyu
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract SGTv2 is ERC20Burnable, ERC20Permit {
    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply,
        address owner
    ) ERC20(name, symbol) ERC20Permit(name) {
        _mint(owner, initialSupply);
    }
}