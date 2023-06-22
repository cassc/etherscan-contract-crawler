// SPDX-License-Identifier: GPL-3.0-only

// ┏━━━┓━━━━━┏┓━━━━━━━━━┏━━━┓━━━━━━━━━━━━━━━━━━━━━━━
// ┃┏━┓┃━━━━┏┛┗┓━━━━━━━━┃┏━━┛━━━━━━━━━━━━━━━━━━━━━━━
// ┃┗━┛┃┏━┓━┗┓┏┛┏━━┓━━━━┃┗━━┓┏┓┏━┓━┏━━┓━┏━┓━┏━━┓┏━━┓
// ┃┏━┓┃┃┏┓┓━┃┃━┃┏┓┃━━━━┃┏━━┛┣┫┃┏┓┓┗━┓┃━┃┏┓┓┃┏━┛┃┏┓┃
// ┃┃ ┃┃┃┃┃┃━┃┗┓┃┃━┫━┏┓━┃┃━━━┃┃┃┃┃┃┃┗┛┗┓┃┃┃┃┃┗━┓┃┃━┫
// ┗┛ ┗┛┗┛┗┛━┗━┛┗━━┛━┗┛━┗┛━━━┗┛┗┛┗┛┗━━━┛┗┛┗┛┗━━┛┗━━┛
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

pragma solidity ^0.8.0;

/// @title Ante V0.6 Ante Pool Factory Controller smart contract
/// @notice Contract that handles the whitelisted ERC20 tokens
interface IAntePoolFactoryController {
    /// @notice Emitted when a new token is added to whitelist.
    /// @param tokenAddr The ERC20 token address that was added
    /// @param min The minimum allowed stake amount expressed in the token's decimals
    event TokenAdded(address indexed tokenAddr, uint256 min);

    /// @notice Emitted when a token is removed from whitelist.
    /// @param tokenAddr The ERC20 token address that was added
    event TokenRemoved(address indexed tokenAddr);

    /// @notice Emitted when a token minimum stake is updated.
    /// @param tokenAddr The ERC20 token address that was added
    /// @param min The minimum allowed stake amount expressed in the token's decimals
    event TokenMinimumUpdated(address indexed tokenAddr, uint256 min);

    /// @notice Emitted when the ante pool implementation contract address is updated.
    /// @param oldImplAddress The address of the old implementation contract
    /// @param implAddress The address of the new implementation contract
    event AntePoolImplementationUpdated(address oldImplAddress, address implAddress);

    /// @notice Adds the provided token to the whitelist
    /// @param _tokenAddr The ERC20 token address to be added
    /// @param _min The minimum allowed stake amount expressed in the token's decimals
    function addToken(address _tokenAddr, uint256 _min) external;

    /// @notice Adds multiple tokens to the whitelist only if they do not already exist
    /// It reverts only if no token was added
    /// @param _tokenAddresses An array of ERC20 token addresses
    /// @param _mins An array of minimum allowed stake amount expressed in the token's decimals
    function addTokens(address[] memory _tokenAddresses, uint256[] memory _mins) external;

    /// @notice Removes the provided token address from the whitelist
    /// @param _tokenAddr The ERC20 token address to be removed
    function removeToken(address _tokenAddr) external;

    /// @notice Sets the address of AntePool implementation contract
    /// This is used by the factory when creating a new pool
    /// @param _antePoolLogicAddr The address of the new implementation contract
    function setPoolLogicAddr(address _antePoolLogicAddr) external;

    /// @notice Check if the provided token address exists in the whitelist
    /// @param _tokenAddr The ERC20 token address to be checked
    /// @return true if the provided token is in the whitelist
    function isTokenAllowed(address _tokenAddr) external view returns (bool);

    /// @notice Set the minimum allowed stake amount for a token in the whitelist
    /// @param _tokenAddr The ERC20 token address to be modified
    /// @param _min The minimum allowed stake amount expressed in the token's decimals
    function setTokenMinimum(address _tokenAddr, uint256 _min) external;

    /// @notice Get the minimum allowed stake amount for a token in the whitelist
    /// @param _tokenAddr The ERC20 token address to be checked
    /// @return The minimum stake amount, expressed in the token's decimals
    function getTokenMinimum(address _tokenAddr) external view returns (uint256);

    /// @notice Retrieves an array of all whitelisted tokens
    /// @return A list of ERC20 tokens that are allowed to be used by the factory.
    function getAllowedTokens() external view returns (address[] memory);

    /// @notice Returns the address of AntePool implementation contract
    /// @return Address of the AntePool implementation contract
    function antePoolLogicAddr() external view returns (address);
}