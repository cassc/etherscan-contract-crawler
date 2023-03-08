// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

/// @notice Smart wallet to hold loan collateral on the Sodium Protocol
/// @dev This contract is deployed as the implementation for proxy wallets
interface ISodiumWallet {
    /// @param borrower_ The owner of this wallet
    /// @param core_ The address of the Core
    /// @param registry_ Used by the wallets to determine external call permission
    function initialize(
        address borrower_,
        address core_,
        address registry_
    ) external;

    /// @notice Used by borrower to make calls with their Sodium wallet
    /// @dev Uses `registry` to determine call (address & function selector) permission
    /// @param contractAddresses_ An in-order array of the addresses to which the calls are to be made
    /// @param calldatas_ The in-order calldatas to be used during those calls (elements at same index correspond)
    /// @param values_ The in-order Wei amounts to be sent with those calls (again elements at same index correspond)
    function execute(
        address[] calldata contractAddresses_,
        bytes[] memory calldatas_,
        uint256[] calldata values_
    ) external payable;

    /// @notice Called by core to transfer an ERC721 token held in wallet
    function transferERC721(
        address recipient_,
        address tokenAddress_,
        uint256 tokenId_
    ) external;

    /// @notice Called by core to transfer an ERC1155 token held in wallet
    function transferERC1155(
        address recipient,
        address tokenAddress,
        uint256 tokenId
    ) external;
}