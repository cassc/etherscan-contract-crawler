// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

interface IERC721Mintable {
    /**
     * @notice Mints token to address with specified URI
     * @param recipient Address of token recipient
     * @param amount Amount of unique tokens to be minted
     */
    function mint(address recipient, uint256 amount) external;

    /**
     * @notice Mints `amount` number of unique tokens to addresses with specified URI in batch
     * @param recipients List of addresses of token recipients
     * @param amounts List of amounts of tokens to be minted
     */
    function mintBatch(address[] memory recipients, uint256[] memory amounts) external;
}