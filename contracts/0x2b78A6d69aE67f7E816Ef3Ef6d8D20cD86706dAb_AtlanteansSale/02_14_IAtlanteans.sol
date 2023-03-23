/* solhint-disable func-name-mixedcase */
//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.14;

interface IAtlanteans {
    function MAX_SUPPLY() external returns (uint256);

    function MAX_QUANTITY_PER_TX() external returns (uint256);

    /**
     * @notice Allows admin to mint a batch of tokens to a specified arbitrary address
     * @param to The receiver of the minted tokens
     * @param quantity The amount of tokens to be minted
     */
    function mintTo(address to, uint256 quantity) external;
}