// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

import "./ICollectionBase.sol";

/**
 * @dev ERC721 Collection Interface
 */
interface IERC721Collection is ICollectionBase, IERC165 {
    event Unveil(uint256 collectibleId, address tokenAddress, uint256 tokenId);

    struct CollectionState {
        uint16 transactionLimit;
        uint16 purchaseMax;
        uint16 purchaseRemaining;
        uint256 purchasePrice;
        uint16 purchaseLimit;
        uint256 presalePurchasePrice;
        uint16 presalePurchaseLimit;
        uint16 purchaseCount;
        bool active;
        uint256 startTime;
        uint256 endTime;
        uint256 presaleInterval;
        uint256 claimStartTime;
        uint256 claimEndTime;
        bool useDynamicPresalePurchaseLimit;
    }

    /**
     * @dev Pre-mint
     */
    function premint(uint16 amount) external;

    function premint(address[] calldata addresses) external;

    /**
     *  @dev set the tokenURI prefix
     */
    function setTokenURIPrefix(string calldata prefix) external;

    /**
     * @dev Withdraw funds
     */
    function withdraw(address payable recipient, uint256 amount) external;

    /**
     * @dev Set whether or not token transfers are locked until end of sale.
     * @param locked Whether or not transfers are locked
     */
    function setTransferLocked(bool locked) external;

    /**
     * @dev Activate the contract
     */
    function activate(
        uint256 startTime_,
        uint256 duration,
        uint256 presaleInterval_,
        uint256 claimStartTime_,
        uint256 claimEndTime_
    ) external;

    /**
     * @dev Deactivate the contract
     */
    function deactivate() external;

    /**
     * @dev claim
     */
    function claim(
        uint16 amount,
        bytes32 message,
        bytes calldata signature,
        bytes32 nonce
    ) external;

    /**
     * @dev purchase
     */
    function purchase(
        uint16 amount,
        bytes32 message,
        bytes calldata signature,
        bytes32 nonce
    ) external payable;

    /**
     * @dev returns the collection state
     */
    function state() external view returns (CollectionState memory);

    /**
     * @dev Get number of tokens left
     */
    function purchaseRemaining() external view returns (uint16);
}