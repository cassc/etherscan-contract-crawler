// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IMYCToken  {
    /**
    * @notice Returns true if minting is paused on the token.
    */
    function mintingPaused() external returns(bool);

    /**
    * @notice mints new MYC tokens
    * @param to the receiver of the newly minted tokens
    * @param amount the amount of tokens to mint
    */
    function mint(address to, uint256 amount) external;
}