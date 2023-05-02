// SPDX-License-Identifier: CAL
pragma solidity =0.8.18;

import {ERC165CheckerUpgradeable as ERC165Checker} from "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165CheckerUpgradeable.sol";

/// @title Extrospection
/// @notice Exposes certain information available to evm opcodes as public
/// functions that are world callable.
contract Extrospection {
    event BytecodeHash(address sender, address account, bytes32 bytecodeHash);

    event SupportsInterface(
        address sender,
        address account,
        bytes4 interfaceId,
        bool supportsInterface
    );

    /// This is probably only useful in general for offchain processing/indexing
    /// as the bytes MAY be large and cost much gas to retrieve onchain.
    /// @param account_ The account to get bytecode for.
    /// @return The bytecode.
    function bytecode(address account_) external view returns (bytes memory) {
        return account_.code;
    }

    function bytecodeHash(address account_) public view returns (bytes32) {
        bytes32 hash_;
        assembly ("memory-safe") {
            hash_ := extcodehash(account_)
        }
        return hash_;
    }

    function emitBytecodeHash(address account_) external {
        emit BytecodeHash(msg.sender, account_, bytecodeHash(account_));
    }

    function emitSupportsInterface(
        address account_,
        bytes4 interfaceId_
    ) external {
        emit SupportsInterface(
            msg.sender,
            account_,
            interfaceId_,
            ERC165Checker.supportsInterface(account_, interfaceId_)
        );
    }
}