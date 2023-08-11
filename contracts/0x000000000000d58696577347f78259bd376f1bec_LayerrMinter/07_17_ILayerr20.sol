// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ILayerr20
 * @author 0xth0mas (Layerr)
 * @notice ILayerr20 interface defines functions required in an ERC20 token contract to callable by the LayerrMinter contract.
 */
interface ILayerr20 {
    /// @dev Thrown when two or more sets of arrays are supplied that require equal lengths but differ in length.
    error ArrayLengthMismatch();

    /**
     * @notice Mints tokens to the recipients in amounts specified
     * @dev This function should be protected by a role so that it is not callable by any address
     * @param recipients addresses to airdrop tokens to
     * @param amounts amount of tokens to airdrop to recipients
     */
    function airdrop(address[] calldata recipients, uint256[] calldata amounts) external;

    /**
     * @notice Mints `amount` of ERC20 tokens to the `to` address
     * @dev `minter` and `to` may be the same address but are passed as two separate parameters to properly account for
     *      allowlist mints where a minter is using a delegated wallet to mint
     * @param minter address that the minted amount will be credited to
     * @param to address that will receive the tokens being minted
     * @param amount amount of tokens being minted
     */
    function mint(address minter, address to, uint256 amount) external;

    /**
     * @notice Burns `amount` of ERC20 tokens from the `from` address
     * @dev This function should check that the caller has a sufficient spend allowance to burn these tokens
     * @param from address that the tokens will be burned from
     * @param amount amount of tokens to be burned
     */
    function burn(address from, uint256 amount) external;

    /**
     * @notice Returns the total supply of ERC20 tokens in circulation.
     */
    function totalSupply() external view returns(uint256);

    /**
     * @notice Returns the total number of tokens minted for the contract and the number of tokens minted by the `minter`
     * @param minter address to check for number of tokens minted
     * @return totalMinted total number of ERC20 tokens minted since token launch
     * @return minterMinted total number of ERC20 tokens minted by the `minter`
     */
    function totalMintedTokenAndMinter(address minter) external view returns(uint256 totalMinted, uint256 minterMinted);
}