// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IPsionicFarmVault {
    function rewardTokens(uint) external view returns (address);
    function isInitialized() external view returns (bool);
    function PSIONIC_FACTORY() external view returns (address);

    /*
     *   @notice: Initialize the contract
     *   @param _tokens: array of tokens
     *   @param _initialSupply: supply to mint initially
     *   @param _farm: Farm Address
    */
    function initialize(
        address[] memory _tokens,
        uint _initialSupply,
        address _farm
    )  external;

    /*
    *   @notice: Mints amount of tokens to the owner
    *   @param: _amount of tokens to mint
    */
    function adjust(uint _amount, bool shouldMint) external;

    /*
*   @notice: Allows owner to change tokens
    *   @param: new tokens mapping
    */
//    function updateTokens(address[] memory _tokens) external;

    /*
    *   @notice Burn Function to withdraw tokens
    *   @param _to: the address to send the rewards token
    */
    function burn(address _to, uint _liquidity) external;

    function add(address token) external;
    function remove(address token) external;
}