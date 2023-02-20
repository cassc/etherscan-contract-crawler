// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "erc721a-upgradeable/contracts/ERC721AUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/**
 * @title Staking
 * @dev This contract allows users to toggle the staking status of tokens and tracks the amount of
 * time each token is staked for. Only the owner of a token or an approved address can toggle its
 * staking status. The contract also allows the owner to close staking for all tokens.
 */
abstract contract StreetlabERC721AStakeable is ERC721AUpgradeable, OwnableUpgradeable {
    /// @notice Mapping from token ID to timestamp indicating when staking for that token started
    mapping(uint256 => uint256) private stakingStarted;
    /// @notice Mapping from token ID to the total amount of time that token has been staked for
    mapping(uint256 => uint256) private stakingTotal;
    /// @notice Flag indicating whether staking is currently open
    bool private stakingOpened;

    // Events
    event Staked(uint256 indexed tokenId);
    event Unstaked(uint256 indexed tokenId);

    /**
     * @notice Toggle the staking status of some tokens
     * @param tokenIds Array of token IDs to toggle staking for
     */
    function toggleTokensStaking(uint256[] calldata tokenIds) public {
        uint256 n = tokenIds.length;
        for (uint256 i = 0; i < n; ++i) {
            toggleTokenStaking(tokenIds[i]);
        }
    }

    /**
     * @notice Toggle the staking status of a single token
     * @param tokenId ID of the token to toggle staking for
     */
    function toggleTokenStaking(uint256 tokenId) public {
        // Only allow the owner of the token or an approved address to toggle staking
        address owner = ownerOf(tokenId);
        if (_msgSenderERC721A() != owner) {
            // Check if the caller is approved for all operations on the token
            if (!isApprovedForAll(owner, _msgSenderERC721A())) {
                // If not, revert the transaction
                revert ApprovalCallerNotOwnerNorApproved();
            }
        }
        // Check the staking status of the token
        uint256 start = stakingStarted[tokenId];
        if (start == 0) {
            // If the token is not currently staked, start staking
            require(stakingOpened, "Staking is closed.");
            stakingStarted[tokenId] = block.timestamp;
            // Emit the Staked event
            emit Staked(tokenId);
        } else {
            // If the token is currently staked, stop staking and update the total staked time
            stakingTotal[tokenId] += block.timestamp - start;
            stakingStarted[tokenId] = 0;
            // Emit the Unstaked event
            emit Unstaked(tokenId);
        }
    }

    /**
     * @notice Allow the owner to toggle staking for all tokens
     */
    function toggleStaking() external onlyOwner {
        stakingOpened = !stakingOpened;
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override {
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }

    /**
     * @notice This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}