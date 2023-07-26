// SPDX-License-Identifier: None
pragma solidity ^0.8.19;

interface ILelandTrade {
    struct CollectionInfo {
        uint256 tokenId;
        bytes32[] proof;
        uint16 cardNo;
        uint16 rarityId;
    }

    /// @notice Reset initialization factors.
    /// @dev Only owner can call this function.
    function resetInits(
        uint16 _duplicateAmountForUpgrade,
        uint16 _differentAmountForUpgrade,
        uint16 _topRarity
    ) external;

    /// @notice Set merkle tree root.
    /// @dev Only owner can call this function.
    function setRoot(bytes32 _root) payable external;

    /// @notice Deposit Collection to contract.
    /// @dev Only owner can call this function.
    function depositCollection(
        CollectionInfo[] memory _depositCollections
    ) external;

    /// @notice Withdraw deposited collections.
    /// @dev Only owner can call this function.
    function withdrawCollection(uint256[] memory _tokenIds) external;

    /// @notice Get upgraded collection by burning collections.
    /// @notice This will give you a random card without choice.
    /// @dev Anyone can call this function but collection rarity should be same.
    function upgradeCollection(
        CollectionInfo[] memory _collections,
        bool _duplicateMode
    ) external;

    /// @notice Get upgraded collection by burning collections.
    /// @notice This will give you a card of choice.
    /// @dev Anyone can call this function but collection rarity should be same.
    function upgradeCollectionForCertainCollection(
        CollectionInfo[] memory _collections,
        uint256[] memory _targetTokenIds,
        bool _duplicateMode
    ) external;

    /// @notice Get depositedTokenIds by rarity type
    function getDepositedTokenIdsByRarity(
        uint16 _rarityId
    ) external view returns (uint256[] memory);

    event CollectionDeposited(CollectionInfo[] depositCollections);

    event CollectionUpgraded(CollectionInfo[] collections, bool duplicateMode);

    event CollectionUpgradedWithCertainCollection(
        CollectionInfo[] collections,
        uint256[] targetTokenIds,
        bool duplicateMode
    );

    event CollectionWithdrawn(uint256[] tokenIds);

    event ResetInit(
        uint16 _duplicateAmountForUpgrade,
        uint16 _differentAmountForUpgrade,
        uint16 _topRarity
    );
}