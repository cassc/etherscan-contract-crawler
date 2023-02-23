//SPDX-License-Identifier: Unlicense
// Creator: Dai
pragma solidity ^0.8.4;

interface IGenesisOwnerKey {
       /**
     * The caller must own the token or be an approved operator.
     */
    error ApprovalCallerNotOwnerNorApproved();

    /**
     * The token does not exist.
     */
    error ApprovalQueryForNonexistentToken();

    /**
     * The caller cannot approve to their own address.
     */
    error ApproveToCaller();

    /**
     * The caller cannot approve to the current owner.
     */
    error ApprovalToCurrentOwner();

    /**
     * Cannot query the balance for the zero address.
     */
    error BalanceQueryForZeroAddress();

    /**
     * Cannot mint to the zero address.
     */
    error MintToZeroAddress();

    /**
     * The quantity of tokens minted must be more than zero.
     */
    error MintZeroQuantity();

    /**
     * The token does not exist.
     */
    error OwnerQueryForNonexistentToken();

    /**
     * The caller must own the token or be an approved operator.
     */
    error TransferCallerNotOwnerNorApproved();

    /**
     * The token must be owned by `from`.
     */
    error TransferFromIncorrectOwner();

    /**
     * Cannot safely transfer to a contract that does not implement the ERC721Receiver interface.
     */
    error TransferToNonERC721ReceiverImplementer();

    /**
     * Cannot transfer to the zero address.
     */
    error TransferToZeroAddress();

    /**
     * The token does not exist.
     */
    error URIQueryForNonexistentToken();
    
    //Interface
    event Mint(address indexed operator, address indexed to, uint256 quantity);
    event Burn(address indexed operator, uint256 tokenID);
    event UpdateMetadataImage(string);
    event UpdateMetadataExternalUrl(string);
    event UpdateMetadataAnimationUrl(string);
    event SetupPool(address indexed operator, address pool);
    event Locked(address indexed operator, bool locked);
    event TradingAllowed(address indexed operator, bool allowed);
    event MintToPool(address indexed operator, uint256 quantity);
}