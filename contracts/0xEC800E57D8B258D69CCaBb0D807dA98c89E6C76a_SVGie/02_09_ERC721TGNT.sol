// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './ERC165.sol';
import './interfaces/IERC721.sol';
import "./interfaces/IERC721TokenReceiver.sol";
import './interfaces/extensions/IERC721Metadata.sol';

/** @title ERC-721-GNT - Non-Fungible Token Standard optimized for Gating 
 *         (Non-Transferable) only 1 per Wallet
 *  @notice Since it's Non-Transferable, approve, approveForAll, and transfers always throw
 *          ("Read Only NFT Registry" from https://eips.ethereum.org/EIPS/eip-721#rationale)
 *          None of these methods emit Events
 *  @dev By token gating, we optimize for 1 NFT per wallet (as a specific use case)
 *       NFT - Wallet is 1 to 1, so the address is used as tokenId
 */
contract ERC721TGNT is ERC165, IERC721, IERC721Metadata {

    /** A name for the NFTs in the contract
     */
    string private _name;

    /** An abbreviated symbol for the NFTs in the contract
     */
    string private _symbol;

    /** @dev Mapping from address to bool (tokenId IS the owner address)
     */
    mapping(address => bool) private _owners;

    /** @dev Error that is thrown whenever an address for Invalid NFTs is queried
     */
    error ZeroAddressQuery();

    /** @dev Error that is thrown whenever an Invalid NFTs is queried
     */
    error NonExistentTokenId(uint256 tokenId);

    /** @dev Error that is thrown whenever transfers or approvals are called
     */
    error TransferAndApprovalsDisabled();

    /** @dev Error that is thrown when addr already has 1 token
     *  @param addr The address that already owns 1 token
     */
    error AlreadyOwnsToken(address addr);

    /** @dev Error that is thrown when receiver address is a smart contract
     *       and doesn't implement onERC721Received correctly
     *  @param addr The address that already owns 1 token
     */
    error OnERC721ReceivedNotOk(address addr);


    /** @dev constructor
     *  @param name_ A descriptive name for a collection of NFTs in this contract
     *  @param symbol_ An abbreviated name for NFTs in this contract
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Override {IERC165-supportsInterface} to add the supported interfaceIds
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /** @notice A descriptive name for a collection of NFTs in this contract
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /** @notice An abbreviated name for NFTs in this contract
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /** @notice A distinct Uniform Resource Identifier (URI) for a given asset.
     *  @dev Throws if `_tokenId` is not a valid NFT
     *       Empty by default, can be overridden in child contracts.
     */
    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        if (!_exists(_tokenId)) revert NonExistentTokenId(_tokenId);
        return "";
    }

    /** @notice Count all NFTs assigned to an owner, in this case, only 0 or 1
     *  @dev Throws {ZeroAddressQuery} when queried for 0x0 address
     *  @param _owner Address that the balance queried
     *  @return Number of NFTs owned (0 or 1)
     */
    function balanceOf(address _owner) public view virtual override returns (uint256) {
        if (_owner == address(0x0)) revert ZeroAddressQuery();
        if (_owners[_owner]) return 1;
        return 0;
    }

    /** @notice Finds the owner of an NFT
     *  @dev Throws {NonExistentToken} when `_tokenId`is invalid (not minted)
     *  @param _tokenId The identifier for an NFT
     *  @return The address of the owner of the NFT
     */
    function ownerOf(uint256 _tokenId) public view virtual override returns (address) {
        if (!_exists(_tokenId)) revert NonExistentTokenId(_tokenId);
        return (address(uint160(_tokenId)));
    }

    /** @notice Transfers ownership of an NFT from one address to another address
     *  @dev Throws always, (Non-Transferable token)
     *       Emits a {Transfer} event
     */
    function safeTransferFrom(address, address, uint256, bytes memory) public virtual override {
        revert TransferAndApprovalsDisabled();
    }

    /** @notice Transfers the ownership of an NFT from one address to another address
     *  @dev This works identically to the other function with an extra data parameter,
     *       except this function just sets data to "".
     */
    function safeTransferFrom(address, address, uint256) public virtual override {
        revert TransferAndApprovalsDisabled();
    }

    /** @notice Transfers ownership of an NFT from one address to another 
     *          -- CALLER IS RESPONSIBLE IF `_to` IS NOT CAPABLE OF
     *             RECEIVING NFTS (THEY MAY BE PERMANENTLY LOST)
     *  @dev Throws always, (Non-Transferable token)
     *       Emits a {Transfer} event
     *  Emits a {Transfer} event
     */
    function transferFrom(address, address, uint256) public virtual override {
        revert TransferAndApprovalsDisabled();
    }

    /** @notice Change or reaffirm the approved address for an NFT
     *  @dev Throws always, (Non-Transferable token)
     *       Emits a {Approval} event
     */
    function approve(address, uint256) public virtual override {
        revert TransferAndApprovalsDisabled();
    }

    /** @notice Enable or disable approval for a third party ("operator") to manage
     *   all of `msg.sender`'s assets
     *  @dev Throws always, (Non-Transferable token)
     *       Emits a {ApprovalForAll} event
    */
    function setApprovalForAll(address, bool) public virtual override {
        revert TransferAndApprovalsDisabled();
    }

    /** @notice Get the approved address for a single NFT
     *  @dev Throws if `_tokenId` is not a valid NFT.
     *  @param _tokenId The NFT to find the approved address for
     *  @return The zero address, because Approvals are disabled
     */
    function getApproved(uint256 _tokenId) public view virtual override returns (address) {
        if (!_exists(_tokenId)) revert NonExistentTokenId(_tokenId);
        return address(0x0);
    }

    /** @notice Query if an address is an authorized operator for another address
     *  @return False, because approvalForAll is disabled
     */
    function isApprovedForAll(address, address) public view virtual override returns (bool) {
        return false;
    }

    /* *** Internal Functions *** */

    /** @dev Returns if a certain _tokenId exists
     *  @param _tokenId Id of token to query
     *  @return bool true if token exists, false otherwise
     */
    function _exists(uint256 _tokenId) internal view virtual returns (bool) {
        if (uint160(_tokenId) == 0) return false;
        return _owners[address(uint160(_tokenId))];
    }

    /** @dev Mints and transfers a token to `_to`
     *       Throws {ZeroAddressQuery} if `_to` is the Zero address
     *       Throws {AlreadyOwnsToken}
     *       Emits a {Transfer} event, with zero address as `_from`,
     *       `_to` as `_to` and a `_to` as zero padded uint256 as `_tokenId`
     *  @param _to Address to mint the token to
     */
    function _safeMint(address _to) internal virtual {
        if (_to == address(0x0)) revert ZeroAddressQuery();
        if (_owners[_to]) revert AlreadyOwnsToken(_to);
        _owners[_to] = true;
        emit Transfer(address(0x0), _to, uint256(uint160(_to)));
        if (!_isOnERC721ReceivedOk(address(0x0), _to, uint256(uint160(_to)), '')) {
            revert OnERC721ReceivedNotOk(_to);
        }
    }

    /** @dev This is provided for OpenZeppelin's compatibility
     *       It has the same functionality as {_safeMint}
     *  @param _to Address to mint the token to
     *         2nd param is (uint256) IS IGNORED - It just mints
     *         to the Id: uint256(uint160(_to))
     */
    function _safeMint(address _to, uint256) internal virtual {
        _safeMint(_to);
    }

    /** @dev Burns or destroys an NFT with `_tokenId`
     *       Throws {NonExistentToken} when `_tokenId`is invalid (not minted)
     *       Emits a {Transfer} event, with msg.sender as `_from`, zero address
     *       as `_to`, and a zero padded uint256 as `_tokenId`
     *  @param _tokenId Id of the token to be burned
     */
    function _burn(uint256 _tokenId) internal virtual {
        if (!_exists(_tokenId)) revert NonExistentTokenId(_tokenId);

        delete _owners[address(uint160(_tokenId))];

        emit Transfer(msg.sender, address(0x0), uint256(uint160(_tokenId)));
    }

    /** @dev Function to be called on an address only when it is a smart contract
     *  @param _from address from the previous owner of the token
     *  @param _to address that received the token
     *  @param _tokenId Id of the token to be transferred
     *  @param data optional bytes to send in the function call
     */
    function _isOnERC721ReceivedOk(address _from, address _to, uint256 _tokenId, bytes memory data) private returns (bool) {
        // if `_to` is NOT a smart contract, return true
        if (_to.code.length == 0) return true;

        // `_to` is a smart contract, check that it implements onERC721Received correctly
        try IERC721TokenReceiver(_to).onERC721Received(msg.sender, _from, _tokenId, data) returns (bytes4 retval) {
            return retval == IERC721TokenReceiver.onERC721Received.selector;
        } catch (bytes memory errorMessage) {
            // if we don't get a message, revert with custom error
            if (errorMessage.length == 0) revert OnERC721ReceivedNotOk(_to);
            
            // if we get a message, we revert with that message
            assembly {
                revert(add(32, errorMessage), mload(errorMessage))
            }
        }
    }

}