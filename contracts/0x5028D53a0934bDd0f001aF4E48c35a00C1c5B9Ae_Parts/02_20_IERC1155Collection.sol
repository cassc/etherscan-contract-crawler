// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// @author: manifold.xyz

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

import "./ICollectionBase.sol";

/**
 * @dev ERC1155 Collection Interface
 */
interface IERC1155Collection is ICollectionBase, IERC165 {

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
     * @dev Activates the contract.
     */
    function activate() external;

    /**
     * @dev Deactivate the contract
     */
    function deactivate() external;

    /**
     * @dev Set the URI for the metadata for the collection.
     * @param uri The metadata URI.
     */
    function setCollectionURI(string calldata uri) external;

    /**
     * @dev returns the collection state
     */
    function state() external view returns (CollectionState memory);

    /**
     * @dev Total amount of tokens remaining for the given token id.
     */
    function purchaseRemaining() external view returns (uint16);

    /**
     * @dev Withdraw funds (requires contract admin).
     * @param recipient The address to withdraw funds to
     * @param amount The amount to withdraw
     */
    function withdraw(address payable recipient, uint256 amount) external;

    /**
     * @dev Get balance of address. Similar to IERC1155-balanceOf, but doesn't require token ID
     * @param owner The address to get the token balance of
     */
    function balanceOf(address owner) external view returns (uint256);
}