// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./SelfMulticall.sol";
import "./interfaces/IExtendedSelfMulticall.sol";

/// @title Contract that extends SelfMulticall to fetch some of the global
/// variables
/// @notice Available global variables are limited to the ones that Airnode
/// tends to need
contract ExtendedSelfMulticall is SelfMulticall, IExtendedSelfMulticall {
    /// @notice Returns the chain ID
    /// @return Chain ID
    function getChainId() external view override returns (uint256) {
        return block.chainid;
    }

    /// @notice Returns the account balance
    /// @param account Account address
    /// @return Account balance
    function getBalance(
        address account
    ) external view override returns (uint256) {
        return account.balance;
    }

    /// @notice Returns if the account contains bytecode
    /// @dev An account not containing any bytecode does not indicate that it
    /// is an EOA or it will not contain any bytecode in the future.
    /// Contract construction and `SELFDESTRUCT` updates the bytecode at the
    /// end of the transaction.
    /// @return If the account contains bytecode
    function containsBytecode(
        address account
    ) external view override returns (bool) {
        return account.code.length > 0;
    }

    /// @notice Returns the current block number
    /// @return Current block number
    function getBlockNumber() external view override returns (uint256) {
        return block.number;
    }

    /// @notice Returns the current block timestamp
    /// @return Current block timestamp
    function getBlockTimestamp() external view override returns (uint256) {
        return block.timestamp;
    }

    /// @notice Returns the current block basefee
    /// @return Current block basefee
    function getBlockBasefee() external view override returns (uint256) {
        return block.basefee;
    }
}