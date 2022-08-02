// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IFlashStrategy {
    event BurnedFToken(address indexed _address, uint256 _tokenAmount, uint256 _yieldReturned);

    // This is how principal will be deposited into the contract
    // The Flash protocol allows the strategy to specify how much
    // should be registered. This allows the strategy to manipulate (eg take fee)
    // on the principal if the strategy requires
    function depositPrincipal(uint256 _tokenAmount) external returns (uint256);

    // This is how principal will be returned from the contract
    function withdrawPrincipal(uint256 _tokenAmount) external;

    // Responsible for instant upfront yield. Takes fERC20 tokens specific to this
    // strategy. The strategy is responsible for returning some amount of principal tokens
    function burnFToken(
        uint256 _tokenAmount,
        uint256 _minimumReturned,
        address _yieldTo
    ) external returns (uint256);

    // This should return the current total of all principal within the contract
    function getPrincipalBalance() external view returns (uint256);

    // This should return the current total of all yield generated to date (including bootstrapped tokens)
    function getYieldBalance() external view returns (uint256);

    // This should return the principal token address (eg DAI)
    function getPrincipalAddress() external view returns (address);

    // View function which quotes how many principal tokens would be returned if x
    // fERC20 tokens are burned
    function quoteMintFToken(uint256 _tokenAmount, uint256 duration) external view returns (uint256);

    // View function which quotes how many principal tokens would be returned if x
    // fERC20 tokens are burned
    // IMPORTANT NOTE: This should utilise bootstrap tokens if they exist
    // bootstrapped tokens are any principal tokens that exist within the smart contract
    function quoteBurnFToken(uint256 _tokenAmount) external view returns (uint256);

    // The function to set the fERC20 address within the strategy
    function setFTokenAddress(address _fTokenAddress) external;

    // This should return what the maximum stake duration is
    function getMaxStakeDuration() external view returns (uint256);
}