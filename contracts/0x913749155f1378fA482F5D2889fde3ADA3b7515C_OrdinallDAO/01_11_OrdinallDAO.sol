// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Snapshot} from
    "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";
import {ERC20Burnable} from
    "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

/// @title OrdinallDAO
/// @author BlockHubDAO

contract OrdinallDAO is ERC20, ERC20Snapshot, ERC20Burnable, Ownable {
    uint256 public currentSnapshotId;

    constructor(string memory tokenName, string memory tokenSymbol)
        ERC20(tokenName, tokenSymbol)
    {}

    /// @dev Mints new governance tokens.
    /// @param recipient_ - address of the minting recipient
    /// @param amount_ - amount of tokens to mint
    function mintNewVotingTokens(address recipient_, uint256 amount_)
        external
        onlyOwner
    {
        _mint(recipient_, amount_);
    }

    /// @dev Allows a super-admin or the multisig to initiate a snapshot
    function snapshot() external onlyOwner {
        currentSnapshotId = _snapshot();
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        virtual
        override(ERC20, ERC20Snapshot)
    {
        super._beforeTokenTransfer(from, to, amount);
    }
}