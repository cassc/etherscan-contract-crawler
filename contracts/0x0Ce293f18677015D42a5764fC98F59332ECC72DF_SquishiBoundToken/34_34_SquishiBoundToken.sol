// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IERC1155, TrackableBurnableERC1155} from "../extensions/ERC1155/TrackableBurnableERC1155.sol";

/**
 * @title SquishiBoundToken
 * @custom:website www.squishiverse.com
 * @author Lozz (@lozzereth / www.allthingsweb3.com)
 * @notice Squishiverse "SquishiBound" Soul-Bound Token (SBT) implementation contract.
 */
contract SquishiBoundToken is TrackableBurnableERC1155 {
    /// @dev Thrown when an approval is made while untransferable
    error Unapprovable();

    /// @dev Thrown when making an transfer while untransferable
    error Untransferable();

    function initialize(string memory _metadataUri) public initializer {
        __TrackableBurnableERC1155_init(
            "SquishiBound Token",
            "SBT",
            _metadataUri
        );
    }

    /**
     * @inheritdoc TrackableBurnableERC1155
     */
    function burn(
        address account,
        uint256 id,
        uint256 value
    )
        public
        virtual
        override(TrackableBurnableERC1155)
        ownerOrApproved(account)
    {
        super.burn(account, id, value);
    }

    /**
     * @notice Airdrop to specified addresses
     * @param accounts Account addresses
     * @param id Token id to airdrop
     * @param quantity Quantity to airdrop
     */
    function airdrop(
        address[] memory accounts,
        uint256 id,
        uint256 quantity
    ) external onlyOwner {
        for (uint256 i; i < accounts.length; i++) {
            _mint(accounts[i], id, quantity, "");
        }
    }

    /**
     * @inheritdoc IERC1155
     */
    function setApprovalForAll(address, bool) public pure override {
        revert Unapprovable();
    }

    /**
     * @inheritdoc IERC1155
     */
    function safeTransferFrom(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public pure override {
        revert Untransferable();
    }

    /**
     * @inheritdoc IERC1155
     */
    function safeBatchTransferFrom(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override {
        revert Untransferable();
    }
}