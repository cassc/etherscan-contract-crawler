// SPDX-License-Identifier: MIT
// Copyright (c) 2022 Fellowship

pragma solidity ^0.8.7;

import "./TokenBase.sol";

contract LightYearsPasses is TokenBase {
    /// @notice Selection contract where tokens from this contract can be used
    address public selector;

    uint256 private constant MAX_AUCTION_ID = 95;
    uint256 private nextAuctionId = 1;

    error SoldOut();

    event Reservation(uint256 passId);

    constructor(
        string memory name,
        string memory symbol,
        address royaltyReceiver,
        string memory baseURI_
    ) TokenBase(name, symbol, 1, 98, royaltyReceiver) {
        baseURI = baseURI_;
    }

    // HOLDER FUNCTIONS

    /// @notice Enable or disable approval for an `operator` to manage all assets belonging to the sender
    /// @dev Emits the ApprovalForAll event. The contract MUST allow multiple operators per owner.
    /// @param operator Address to add to the set of authorized operators
    /// @param approved True to grant approval, false to revoke approval
    function setApprovalForAll(address operator, bool approved) public override {
        // CHECKS inputs
        require(operator != selector, "Cannot change approval on selection contract");
        // CHECKS + EFFECTS
        super.setApprovalForAll(operator, approved);
    }

    // MINTER FUNCTIONS

    /// @notice Mint the next available pass to the given `recipient`
    /// @dev Can only be called by the `minter` address. Cannot mint tokens with IDs lower than 3 or higher than 97.
    function mint(address recipient) external onlyMinter returns (uint256 id) {
        // CHECKS inputs
        if (nextAuctionId > MAX_AUCTION_ID) revert SoldOut();
        // CHECKS + EFFECTS (not _safeMint, so no interactions)
        unchecked {
            id = nextAuctionId++;
            _mint(recipient, id);
            totalSupply++;
        }
    }

    // OWNER FUNCTIONS

    /// @notice Mint the reserved passes (1, 2, 98, 99, and 100) to a designated recipient
    /// @dev Can only be called by the contract `owner`
    function mintHeldTokens(address recipient) external onlyOwner {
        _mint(recipient, 96);
        _mint(recipient, 97);
        _mint(recipient, 98);

        // More EFFECTS
        unchecked {
            totalSupply += 3;
        }

        emit Reservation(96);
        emit Reservation(97);
        emit Reservation(98);
    }

    /// @notice Set the address of the selector contract
    /// @dev Can only be called by the contract `owner`
    function setSelector(address selector_) external onlyOwner {
        // EFFECTS (checks already handled by modifiers)
        selector = selector_;
    }

    // VIEW FUNCTIONS

    /// @notice Query if an address is an authorized operator for another address
    /// @dev to streamline the selection process, always returns true if the operator is `selector`
    /// @param owner The address that owns the NFTs
    /// @param operator The address that acts on behalf of the owner
    /// @return True if `operator` is an approved operator for `owner`, false otherwise
    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return operator == selector || super.isApprovedForAll(owner, operator);
    }

    /// @notice Query if a contract implements an interface
    /// @dev Interface identification is specified in ERC-165. This function uses less than 30,000 gas.
    /// @param interfaceId The interface identifier, as specified in ERC-165
    /// @return `true` if the contract implements `interfaceID` and `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceId) public pure virtual override returns (bool) {
        return
            interfaceId == 0x6a627842 || // Selector for: mint(address)
            super.supportsInterface(interfaceId);
    }

    function allOwners() public view returns (address[MAX_AUCTION_ID + 3] memory owners) {
        uint256 maxIter = MAX_AUCTION_ID == nextAuctionId - 1 ? MAX_AUCTION_ID + 3 : nextAuctionId - 1;
        for (uint256 i = 0; i < maxIter; i++) {
            owners[i] = ownerOf(i+1);
        }
        return owners;
    }
}