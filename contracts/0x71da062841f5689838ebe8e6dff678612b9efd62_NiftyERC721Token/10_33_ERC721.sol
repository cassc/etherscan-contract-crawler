// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./ERC721Errors.sol";
import "../interfaces/IERC721.sol";
import "../interfaces/IERC721Receiver.sol";
import "../interfaces/IERC721Metadata.sol";
import "../interfaces/IERC721Cloneable.sol";
import "../libraries/Address.sol";
import "../libraries/Context.sol";
import "../libraries/Strings.sol";
import "../utils/ERC165.sol";
import "../utils/GenericErrors.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
abstract contract ERC721 is Context, ERC165, ERC721Errors, GenericErrors, IERC721Metadata, IERC721Cloneable {
    using Address for address;
    using Strings for uint256;

    // Only allow ERC721 to be initialized once
    bool internal initializedERC721;

    // Token name
    string internal tokenName;

    // Token symbol
    string internal tokenSymbol;

    // Base URI For Offchain Metadata
    string internal baseMetadataURI; 

    // Mapping from token ID to owner address
    mapping(uint256 => address) internal owners;

    // Mapping owner address to token count
    mapping(address => uint256) internal balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) internal tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) internal operatorApprovals;    

    function initializeERC721(string memory name_, string memory symbol_, string memory baseURI_) public override {
        require(!initializedERC721, ERROR_REINITIALIZATION_NOT_PERMITTED);
        tokenName = name_;
        tokenSymbol = symbol_;
        _setBaseURI(baseURI_);
        initializedERC721 = true;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IERC721Cloneable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */    
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), ERROR_QUERY_FOR_ZERO_ADDRESS);
        return balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = owners[tokenId];
        require(owner != address(0), ERROR_QUERY_FOR_NONEXISTENT_TOKEN);
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */    
    function name() public view virtual override returns (string memory) {
        return tokenName;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */    
    function symbol() public view virtual override returns (string memory) {
        return tokenSymbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */     
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), ERROR_QUERY_FOR_NONEXISTENT_TOKEN);

        string memory uriBase = baseURI();
        return bytes(uriBase).length > 0 ? string(abi.encodePacked(uriBase, tokenId.toString())) : "";
    }

    function baseURI() public view virtual returns (string memory) {
        return baseMetadataURI;
    }

    /**
     * @dev Internal function to set the base URI
     */
    function _setBaseURI(string memory uri) internal {
        baseMetadataURI = uri;        
    }

    /**
     * @dev See {IERC721-approve}.
     */    
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);
        require(to != owner, ERROR_APPROVAL_TO_CURRENT_OWNER);

        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()), ERROR_NOT_OWNER_NOR_APPROVED);

        _approve(owner, to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */    
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), ERROR_QUERY_FOR_NONEXISTENT_TOKEN);
        return tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */    
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), ERROR_APPROVE_TO_CALLER);
        operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);        
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */    
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */    
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {        
        (address owner, bool isApprovedOrOwner) = _isApprovedOrOwner(_msgSender(), tokenId);
        require(isApprovedOrOwner, ERROR_NOT_OWNER_NOR_APPROVED);
        _transfer(owner, from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */    
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */    
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual override {
        transferFrom(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), ERROR_NOT_AN_ERC721_RECEIVER);
    }    

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */    
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (address owner, bool isApprovedOrOwner) {
        owner = owners[tokenId];
        require(owner != address(0), ERROR_QUERY_FOR_NONEXISTENT_TOKEN);
        isApprovedOrOwner = (spender == owner || tokenApprovals[tokenId] == spender || isApprovedForAll(owner, spender));
    }   
    
    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ownerOf(tokenId);
        bool isApprovedOrOwner = (_msgSender() == owner || tokenApprovals[tokenId] == _msgSender() || isApprovedForAll(owner, _msgSender()));
        require(isApprovedOrOwner, ERROR_NOT_OWNER_NOR_APPROVED);

        // Clear approvals        
        _clearApproval(owner, tokenId);

        balances[owner] -= 1;
        _clearOwnership(tokenId);

        emit Transfer(owner, address(0), tokenId);
    }    

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(address owner, address from, address to, uint256 tokenId) internal virtual {
        require(owner == from, ERROR_TRANSFER_FROM_INCORRECT_OWNER);
        require(to != address(0), ERROR_TRANSFER_TO_ZERO_ADDRESS);        

        // Clear approvals from the previous owner        
        _clearApproval(owner, tokenId);

        balances[from] -= 1;
        balances[to] += 1;
        _setOwnership(to, tokenId);
        
        emit Transfer(from, to, tokenId);        
    }

    /**
     * @dev Equivalent to approving address(0), but more gas efficient
     *
     * Emits a {Approval} event.
     */
    function _clearApproval(address owner, uint256 tokenId) internal virtual {
        delete tokenApprovals[tokenId];
        emit Approval(owner, address(0), tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address owner, address to, uint256 tokenId) internal virtual {
        tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }    

    function _clearOwnership(uint256 tokenId) internal virtual {
        delete owners[tokenId];
    }

    function _setOwnership(address to, uint256 tokenId) internal virtual {
        owners[tokenId] = to;
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     *
     * @dev Slither identifies an issue with unused return value.
     * Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#unused-return
     * This should be a non-issue.  It is the standard OpenZeppelin implementation which has been heavily used and audited.
     */     
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal returns (bool) {
        if (to.isContract()) {            
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert(ERROR_NOT_AN_ERC721_RECEIVER);
                } else {                    
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }    
}