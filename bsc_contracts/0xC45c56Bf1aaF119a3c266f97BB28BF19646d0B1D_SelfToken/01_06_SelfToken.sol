// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SelfToken is ERC20, Ownable {
    uint256 public constant INITIAL_SUPPLY = 25_000_000;
    uint256 public constant MAX_SUPPLY = 35_000_000;

    /// @dev Contructor of token contract
    /// @param superOwner Addres of owner, this address can mint and burn tokens
    /// @param initialMintTarget Address of wallet on which the initial minting of 25m tokens will be made
    constructor(address superOwner, address initialMintTarget) ERC20("SelfToken", "SELF") {
        _transferOwnership(superOwner);
        _mint(initialMintTarget, INITIAL_SUPPLY); // Initial mint of 25M tokens
    }

    /// @dev Override default token's decimals to 0
    function decimals() public view virtual override returns (uint8) {
        return 0;
    }

    /// @dev Function to mint tokens on specific address
    /// @param to Address of mint target
    /// @param amount Amount of tokens to mint
    /// @notice Max supply of tokens is 35M and it can't be exceeded. This function is available only for owner
    function mint(address to, uint256 amount) external onlyOwner {
        bool isMaxSupplyNotExceeded = totalSupply() + amount <= MAX_SUPPLY;
        require(isMaxSupplyNotExceeded, "Max supply exceeded");

        _mint(to, amount);
    }

    /// @dev Function to burn tokens
    /// @param amount Amount of tokens to burn
    /// @notice This function is available only for owner. The owner can burn only owned tokens
    function burn(uint256 amount) external onlyOwner {
        _burn(msg.sender, amount);
    }
}