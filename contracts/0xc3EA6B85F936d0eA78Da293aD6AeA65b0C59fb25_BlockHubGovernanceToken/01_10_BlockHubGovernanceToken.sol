// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Snapshot.sol";

//   ____  _      ____   _____ _  ___    _ _    _ ____    _____          ____
//  |  _ \| |    / __ \ / ____| |/ / |  | | |  | |  _ \  |  __ \   /\   / __ \
//  | |_) | |   | |  | | |    | ' /| |__| | |  | | |_) | | |  | | /  \ | |  | |
//  |  _ <| |   | |  | | |    |  < |  __  | |  | |  _ <  | |  | |/ /\ \| |  | |
//  | |_) | |___| |__| | |____| . \| |  | | |__| | |_) | | |__| / ____ \ |__| |
//  |____/|______\____/ \_____|_|\_\_|  |_|\____/|____/  |_____/_/    \_\____/

/// @title BlockHub DAO governance token
/// @author BlockHub DAO

contract BlockHubGovernanceToken is ERC20Snapshot, Ownable {
    address public multisigAddress;
    uint256 public currentSnapshotId;

    event MultisigAddressUpdated(address indexed newMultisigAddress);

    /// @dev Verifies that the address that calls the function is either the super-admin or the multisig
    modifier onlyAllowed() {
        require(
            owner() == msg.sender || multisigAddress == msg.sender,
            "Auth: Caller is not allowed"
        );
        _;
    }

    /// @dev Verifies that the address in param is valid
    /// @param add - an address
    modifier validAddress(address add) {
        require(add != address(0), "Valid: Cannot use zero address");
        _;
    }

    constructor(
        string memory tokenName,
        string memory tokenSymbol,
        uint8 tokenDecimals
    ) ERC20(tokenName, tokenSymbol) {
        _setupDecimals(tokenDecimals);
    }

    /// @dev Modifies the address used for the multisig
    /// @param newAddress - The address of the multisig
    /// @return bool
    function setMultisigAddress(address newAddress)
        external
        onlyAllowed
        validAddress(newAddress)
        returns (bool)
    {
        multisigAddress = newAddress;
        emit MultisigAddressUpdated(newAddress);
        return true;
    }

    /// @dev Mints new governance tokens from either the super-admin or the multisig
    /// @param recipient_ - address of the minting recipient
    /// @param amount_ - amount of tokens to mint
    /// @return bool
    function mintNewVotingTokens(address recipient_, uint256 amount_)
        external
        validAddress(recipient_)
        onlyAllowed
        returns (bool)
    {
        _mint(recipient_, amount_);
    }

    /// @dev Allows a super-admin or the multisig to initiate a snapshot
    function snapshot() external onlyAllowed {
        currentSnapshotId = _snapshot();
    }
}