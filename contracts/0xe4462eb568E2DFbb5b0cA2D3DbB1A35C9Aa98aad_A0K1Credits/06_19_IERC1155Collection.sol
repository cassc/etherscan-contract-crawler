// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// @author: manifold.xyz

import "./ICollectionBase.sol";

/**
 * @dev ERC1155 Collection Interface
 */
interface IERC1155Collection is ICollectionBase {

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
    }

    /**
     * @dev Activates the contract.
     * @param startTime_ The UNIX timestamp in seconds the sale should start at.
     * @param duration The number of seconds the sale should remain active.
     * @param presaleInterval_ The period of time the contract should only be active for presale.
     */
    function activate(uint256 startTime_, uint256 duration, uint256 presaleInterval_, uint256 claimStartTime_, uint256 claimEndTime_) external;

    /**
     * @dev Deactivate the contract
     */
    function deactivate() external;

    /**
     * @dev Pre-mint tokens to the owner. Sale must not be active.
     * @param amount The number of tokens to mint.
     */
    function premint(uint16 amount) external;

    /**
     * @dev Pre-mint tokens to the list of addresses. Sale must not be active.
     * @param amounts The amount of tokens to mint per address.
     * @param addresses The list of addresses to mint a token to.
     */
    function premint(uint16[] calldata amounts, address[] calldata addresses) external;

    /**
     * @dev Claim - mint with validation.
     * @param amount The number of tokens to mint.
     * @param message Signed message to validate input args.
     * @param signature Signature of the signer to recover from signed message.
     * @param nonce Manifold-generated nonce.
     */
    function claim(uint16 amount, bytes32 message, bytes calldata signature, string calldata nonce) external;

    /**
     * @dev Purchase - mint with validation.
     * @param amount The number of tokens to mint.
     * @param message Signed message to validate input args.
     * @param signature Signature of the signer to recover from signed message.
     * @param nonce Manifold-generated nonce.
     */
    function purchase(uint16 amount, bytes32 message, bytes calldata signature, string calldata nonce) external payable;

    /**
     * @dev Mint reserve tokens to the owner. Sale must be complete.
     * @param amount The number of tokens to mint.
     */
    function mintReserve(uint16 amount) external;

    /**
     * @dev Mint reserve tokens to the list of addresses. Sale must be complete.
     * @param amounts The amount of tokens to mint per address.
     * @param addresses The list of addresses to mint a token to.
     */
    function mintReserve(uint16[] calldata amounts, address[] calldata addresses) external;

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
     * @dev Set whether or not token transfers are locked until end of sale.
     * @param locked Whether or not transfers are locked
     */
    function setTransferLocked(bool locked) external;

    /**
     * @dev Update royalties
     * @param recipient The address to set as the royalty recipient
     * @param bps The basis points to set as the royalty
     */
    function updateRoyalties(address payable recipient, uint256 bps) external;

    /**
     * @dev Get the current royalty recipient and amount
     */
    function getRoyalties(uint256) external view returns (address payable recipient, uint256 bps);

    /**
     * @dev EIP-2981 compatibility to determine royalty info on sale
     */
    function royaltyInfo(uint256, uint256 salePrice) external view returns (address receiver, uint256 royaltyAmount);

    /**
     * @dev Get balance of address. Similar to IERC1155-balanceOf, but doesn't require token ID
     * @param owner The address to get the token balance of
     */
    function balanceOf(address owner) external view returns (uint256);

    /**
     * @dev Destroys `amount` tokens from `from`
     * @param from The address to remove tokens from
     * @param amount The amount of tokens to remove
     */
    function burn(address from, uint16 amount) external;
}