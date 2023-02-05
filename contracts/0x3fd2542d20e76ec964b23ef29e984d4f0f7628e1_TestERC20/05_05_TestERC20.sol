/// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title A test ERC-20 contract with unlimited mints
/// @author Syndicate Inc.
/// @notice This is a test ERC-20 contract with unlimited open mints. It is for
/// testing purposes only and should not be used in prduction.
/// @dev Call the mint function to mint tokens. This token has 18 decimals.
contract TestERC20 is ERC20 {
    uint256 public constant MAX_AMOUNT = 1000 * 10**18;

    constructor() ERC20("Test ERC20", "TEST") {}

    /// @notice Mint test ERC-20 tokens
    /// @dev Max mint in one transaction is 1,000 ETH. This prevents someone
    /// from minting the max amount of a uint256.
    /// @param to The address to mint tokens to
    /// @param amount The amount of tokens to mint. These are raw values, not
    /// display values. You should multiply your desired value by 10^18 if you
    /// want the values in ETH terms. The convertETHToWei function can be used
    /// for this.
    function mint(address to, uint256 amount) external {
        require(amount < MAX_AMOUNT, "TestERC20: Max mint is 1,000 ETH");
        _mint(to, amount);
    }

    /// @notice Mint 1 ETH of test ERC-20 tokens
    /// @param to The address to mint tokens to
    function mint(address to) external {
        _mint(to, 1 ether);
    }

    /// @notice Quick convenience function to convert ETH to wei
    /// @param amount The amount of tokens in ETH terms
    /// @return The amount of tokens in wei terms
    function convertETHtoWei(uint256 amount) public pure returns (uint256) {
        return amount * 10**18;
    }
}