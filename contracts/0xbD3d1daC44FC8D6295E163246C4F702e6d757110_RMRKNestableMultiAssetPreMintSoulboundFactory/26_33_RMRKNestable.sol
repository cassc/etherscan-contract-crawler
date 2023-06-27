// SPDX-License-Identifier: Apache-2.0

//Generally all interactions should propagate downstream

pragma solidity ^0.8.18;

import "./IERC6059.sol";
import "../core/RMRKCore.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "../library/RMRKErrors.sol";

/**
 * @title RMRKNestable
 * @author RMRK team
 * @notice Smart contract of the RMRK Nestable module.
 * @dev This contract is hierarchy agnostic and can support an arbitrary number of nested levels up and down, as long as
 *  gas limits allow it.
 */
contract RMRKNestable is Context, IERC165, IERC721, IERC6059, RMRKCore {
    using Address for address;

    uint256 private constant _MAX_LEVELS_TO_CHECK_FOR_INHERITANCE_LOOP = 100;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approver address to approved address
    // The approver is necessary so approvals are invalidated for nested children on transfer
    // WARNING: If a child NFT returns to a previous root owner, old permissions would be active again
    mapping(uint256 => mapping(address => address)) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // ------------------- NESTABLE --------------

    // Mapping from token ID to DirectOwner struct
    mapping(uint256 => DirectOwner) private _RMRKOwners;

    // Mapping of tokenId to array of active children structs
    mapping(uint256 => Child[]) internal _activeChildren;

    // Mapping of tokenId to array of pending children structs
    mapping(uint256 => Child[]) internal _pendingChildren;

    // Mapping of child token address to child token ID to whether they are pending or active on any token
    // We might have a first extra mapping from token ID, but since the same child cannot be nested into multiple tokens
    //  we can strip it for size/gas savings.
    mapping(address => mapping(uint256 => uint256)) internal _childIsInActive;

    // -------------------------- MODIFIERS ----------------------------

    /**
     * @notice Used to verify that the caller is either the owner of the token or approved to manage it by its owner.
     * @dev If the caller is not the owner of the token or approved to manage it by its owner, the execution will be
     *  reverted.
     * @param tokenId ID of the token to check
     */
    function _onlyApprovedOrOwner(uint256 tokenId) private view {
        if (!_isApprovedOrOwner(_msgSender(), tokenId))
            revert ERC721NotApprovedOrOwner();
    }

    /**
     * @notice Used to verify that the caller is either the owner of the token or approved to manage it by its owner.
     * @param tokenId ID of the token to check
     */
    modifier onlyApprovedOrOwner(uint256 tokenId) {
        _onlyApprovedOrOwner(tokenId);
        _;
    }

    /**
     * @notice Used to verify that the caller is approved to manage the given token or it its direct owner.
     * @dev This does not delegate to ownerOf, which returns the root owner, but rater uses an owner from DirectOwner
     *  struct.
     * @dev The execution is reverted if the caller is not immediate owner or approved to manage the given token.
     * @dev Used for parent-scoped transfers.
     * @param tokenId ID of the token to check.
     */
    function _onlyApprovedOrDirectOwner(uint256 tokenId) private view {
        if (!_isApprovedOrDirectOwner(_msgSender(), tokenId))
            revert RMRKNotApprovedOrDirectOwner();
    }

    /**
     * @notice Used to verify that the caller is approved to manage the given token or is its direct owner.
     * @param tokenId ID of the token to check
     */
    modifier onlyApprovedOrDirectOwner(uint256 tokenId) {
        _onlyApprovedOrDirectOwner(tokenId);
        _;
    }

    // ----------------------------- CONSTRUCTOR ------------------------------

    /**
     * @notice Initializes the contract by setting a `name` and a `symbol` to the token collection.
     * @param name_ Name of the token collection
     * @param symbol_ Symbol of the token collection
     */
    constructor(
        string memory name_,
        string memory symbol_
    ) RMRKCore(name_, symbol_) {}

    // ------------------------------- ERC721 ---------------------------------
    /**
     * @inheritdoc IERC165
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual returns (bool) {
        return
            interfaceId == type(IERC165).interfaceId ||
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IERC6059).interfaceId;
    }

    /**
     * @notice Used to retrieve the number of tokens in `owner`'s account.
     * @param owner Address of the account being checked
     * @return The balance of the given account
     */
    function balanceOf(address owner) public view virtual returns (uint256) {
        if (owner == address(0)) revert ERC721AddressZeroIsNotaValidOwner();
        return _balances[owner];
    }

    ////////////////////////////////////////
    //              TRANSFERS
    ////////////////////////////////////////

    /**
     * @notice Transfers a given token from `from` to `to`.
     * @dev Requirements:
     *
     *  - `from` cannot be the zero address.
     *  - `to` cannot be the zero address.
     *  - `tokenId` token must be owned by `from`.
     *  - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * @dev Emits a {Transfer} event.
     * @param from Address from which to transfer the token from
     * @param to Address to which to transfer the token to
     * @param tokenId ID of the token to transfer
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual onlyApprovedOrDirectOwner(tokenId) {
        _transfer(from, to, tokenId, "");
    }

    /**
     * @notice Used to safely transfer a given token token from `from` to `to`.
     * @dev Requirements:
     *
     *  - `from` cannot be the zero address.
     *  - `to` cannot be the zero address.
     *  - `tokenId` token must exist and be owned by `from`.
     *  - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *  - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     * @dev Emits a {Transfer} event.
     * @param from Address to transfer the tokens from
     * @param to Address to transfer the tokens to
     * @param tokenId ID of the token to transfer
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @notice Used to safely transfer a given token token from `from` to `to`.
     * @dev Requirements:
     *
     *  - `from` cannot be the zero address.
     *  - `to` cannot be the zero address.
     *  - `tokenId` token must exist and be owned by `from`.
     *  - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *  - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     * @dev Emits a {Transfer} event.
     * @param from Address to transfer the tokens from
     * @param to Address to transfer the tokens to
     * @param tokenId ID of the token to transfer
     * @param data Additional data without a specified format to be sent along with the token transaction
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual onlyApprovedOrDirectOwner(tokenId) {
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @inheritdoc IERC6059
     */
    function nestTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 destinationId,
        bytes memory data
    ) public virtual onlyApprovedOrDirectOwner(tokenId) {
        _nestTransfer(from, to, tokenId, destinationId, data);
    }

    /**
     * @notice Used to safely transfer the token form `from` to `to`.
     * @dev The function checks that contract recipients are aware of the ERC721 protocol to prevent tokens from being
     *  forever locked.
     * @dev This internal function is equivalent to {safeTransferFrom}, and can be used to e.g. implement alternative
     *  mechanisms to perform token transfer, such as signature-based.
     * @dev Requirements:
     *
     *  - `from` cannot be the zero address.
     *  - `to` cannot be the zero address.
     *  - `tokenId` token must exist and be owned by `from`.
     *  - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     * @dev Emits a {Transfer} event.
     * @param from Address of the account currently owning the given token
     * @param to Address to transfer the token to
     * @param tokenId ID of the token to transfer
     * @param data Additional data with no specified format, sent in call to `to`
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId, data);
        if (!_checkOnERC721Received(from, to, tokenId, data))
            revert ERC721TransferToNonReceiverImplementer();
    }

    /**
     * @notice Used to transfer the token from `from` to `to`.
     * @dev As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     * @dev Requirements:
     *
     *  - `to` cannot be the zero address.
     *  - `tokenId` token must be owned by `from`.
     * @dev Emits a {Transfer} event.
     * @param from Address of the account currently owning the given token
     * @param to Address to transfer the token to
     * @param tokenId ID of the token to transfer
     * @param data Additional data with no specified format, sent in call to `to`
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        (address immediateOwner, uint256 parentId, ) = directOwnerOf(tokenId);
        if (immediateOwner != from) revert ERC721TransferFromIncorrectOwner();
        if (to == address(0)) revert ERC721TransferToTheZeroAddress();

        _beforeTokenTransfer(from, to, tokenId);
        _beforeNestedTokenTransfer(
            immediateOwner,
            to,
            parentId,
            0,
            tokenId,
            data
        );

        _balances[from] -= 1;
        _updateOwnerAndClearApprovals(tokenId, 0, to);
        _balances[to] += 1;

        emit Transfer(from, to, tokenId);
        emit NestTransfer(immediateOwner, to, parentId, 0, tokenId);

        _afterTokenTransfer(from, to, tokenId);
        _afterNestedTokenTransfer(
            immediateOwner,
            to,
            parentId,
            0,
            tokenId,
            data
        );
    }

    /**
     * @notice Used to transfer a token into another token.
     * @dev Attempting to nest a token into `0x0` address will result in reverted transaction.
     * @dev Attempting to nest a token into itself will result in reverted transaction.
     * @param from Address of the account currently owning the given token
     * @param to Address of the receiving token's collection smart contract
     * @param tokenId ID of the token to transfer
     * @param destinationId ID of the token receiving the given token
     * @param data Additional data with no specified format, sent in the addChild call
     */
    function _nestTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 destinationId,
        bytes memory data
    ) internal virtual {
        (address immediateOwner, uint256 parentId, ) = directOwnerOf(tokenId);
        if (immediateOwner != from) revert ERC721TransferFromIncorrectOwner();
        if (to == address(0)) revert ERC721TransferToTheZeroAddress();
        if (to == address(this) && tokenId == destinationId)
            revert RMRKNestableTransferToSelf();

        // Destination contract checks:
        // It seems redundant, but otherwise it would revert with no error
        if (!to.isContract()) revert RMRKIsNotContract();
        if (!IERC165(to).supportsInterface(type(IERC6059).interfaceId))
            revert RMRKNestableTransferToNonRMRKNestableImplementer();
        _checkForInheritanceLoop(tokenId, to, destinationId);

        _beforeTokenTransfer(from, to, tokenId);
        _beforeNestedTokenTransfer(
            immediateOwner,
            to,
            parentId,
            destinationId,
            tokenId,
            data
        );
        _balances[from] -= 1;
        _updateOwnerAndClearApprovals(tokenId, destinationId, to);
        _balances[to] += 1;

        // Sending to NFT:
        _sendToNFT(immediateOwner, to, parentId, destinationId, tokenId, data);
    }

    /**
     * @notice Used to send a token to another token.
     * @dev If the token being sent is currently owned by an externally owned account, the `parentId` should equal `0`.
     * @dev Emits {Transfer} event.
     * @dev Emits {NestTransfer} event.
     * @param from Address from which the token is being sent
     * @param to Address of the collection smart contract of the token to receive the given token
     * @param parentId ID of the current parent token of the token being sent
     * @param destinationId ID of the tokento receive the token being sent
     * @param tokenId ID of the token being sent
     * @param data Additional data with no specified format, sent in the addChild call
     */
    function _sendToNFT(
        address from,
        address to,
        uint256 parentId,
        uint256 destinationId,
        uint256 tokenId,
        bytes memory data
    ) private {
        IERC6059 destContract = IERC6059(to);
        destContract.addChild(destinationId, tokenId, data);

        emit Transfer(from, to, tokenId);
        emit NestTransfer(from, to, parentId, destinationId, tokenId);

        _afterTokenTransfer(from, to, tokenId);
        _afterNestedTokenTransfer(
            from,
            to,
            parentId,
            destinationId,
            tokenId,
            data
        );
    }

    /**
     * @notice Used to check if nesting a given token into a specified token would create an inheritance loop.
     * @dev If a loop would occur, the tokens would be unmanageable, so the execution is reverted if one is detected.
     * @dev The check for inheritance loop is bounded to guard against too much gas being consumed.
     * @param currentId ID of the token that would be nested
     * @param targetContract Address of the collection smart contract of the token into which the given token would be
     *  nested
     * @param targetId ID of the token into which the given token would be nested
     */
    function _checkForInheritanceLoop(
        uint256 currentId,
        address targetContract,
        uint256 targetId
    ) private view {
        for (uint256 i; i < _MAX_LEVELS_TO_CHECK_FOR_INHERITANCE_LOOP; ) {
            (
                address nextOwner,
                uint256 nextOwnerTokenId,
                bool isNft
            ) = IERC6059(targetContract).directOwnerOf(targetId);
            // If there's a final address, we're good. There's no loop.
            if (!isNft) {
                return;
            }
            // Ff the current nft is an ancestor at some point, there is an inheritance loop
            if (nextOwner == address(this) && nextOwnerTokenId == currentId) {
                revert RMRKNestableTransferToDescendant();
            }
            // We reuse the parameters to save some contract size
            targetContract = nextOwner;
            targetId = nextOwnerTokenId;
            unchecked {
                ++i;
            }
        }
        revert RMRKNestableTooDeep();
    }

    ////////////////////////////////////////
    //              MINTING
    ////////////////////////////////////////

    /**
     * @notice Used to safely mint the token to the specified address while passing the additional data to contract
     *  recipients.
     * @param to Address to which to mint the token
     * @param tokenId ID of the token to mint
     * @param data Additional data to send with the tokens
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId, data);
        if (!_checkOnERC721Received(address(0), to, tokenId, data))
            revert ERC721TransferToNonReceiverImplementer();
    }

    /**
     * @notice Used to mint a specified token to a given address.
     * @dev WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible.
     * @dev Requirements:
     *
     *  - `tokenId` must not exist.
     *  - `to` cannot be the zero address.
     * @dev Emits a {Transfer} event.
     * @dev Emits a {NestTransfer} event.
     * @param to Address to mint the token to
     * @param tokenId ID of the token to mint
     * @param data Additional data with no specified format, sent in call to `to`
     */
    function _mint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _innerMint(to, tokenId, 0, data);

        emit Transfer(address(0), to, tokenId);
        emit NestTransfer(address(0), to, 0, 0, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
        _afterNestedTokenTransfer(address(0), to, 0, 0, tokenId, data);
    }

    /**
     * @notice Used to mint a child token to a given parent token.
     * @param to Address of the collection smart contract of the token into which to mint the child token
     * @param tokenId ID of the token to mint
     * @param destinationId ID of the token into which to mint the new child token
     * @param data Additional data with no specified format, sent in the addChild call
     */
    function _nestMint(
        address to,
        uint256 tokenId,
        uint256 destinationId,
        bytes memory data
    ) internal virtual {
        // It seems redundant, but otherwise it would revert with no error
        if (!to.isContract()) revert RMRKIsNotContract();
        if (!IERC165(to).supportsInterface(type(IERC6059).interfaceId))
            revert RMRKMintToNonRMRKNestableImplementer();

        _innerMint(to, tokenId, destinationId, data);
        _sendToNFT(address(0), to, 0, destinationId, tokenId, data);
    }

    /**
     * @notice Used to mint a child token into a given parent token.
     * @dev Requirements:
     *
     *  - `to` cannot be the zero address.
     *  - `tokenId` must not exist.
     *  - `tokenId` must not be `0`.
     * @param to Address of the collection smart contract of the token into which to mint the child token
     * @param tokenId ID of the token to mint
     * @param destinationId ID of the token into which to mint the new token
     * @param data Additional data with no specified format, sent in call to `to`
     */
    function _innerMint(
        address to,
        uint256 tokenId,
        uint256 destinationId,
        bytes memory data
    ) private {
        if (to == address(0)) revert ERC721MintToTheZeroAddress();
        if (_exists(tokenId)) revert ERC721TokenAlreadyMinted();
        if (tokenId == uint256(0)) revert RMRKIdZeroForbidden();

        _beforeTokenTransfer(address(0), to, tokenId);
        _beforeNestedTokenTransfer(
            address(0),
            to,
            0,
            destinationId,
            tokenId,
            data
        );

        _balances[to] += 1;
        _RMRKOwners[tokenId] = DirectOwner({
            ownerAddress: to,
            tokenId: destinationId
        });
    }

    ////////////////////////////////////////
    //              Ownership
    ////////////////////////////////////////

    /**
     * @inheritdoc IERC6059
     */
    function ownerOf(
        uint256 tokenId
    ) public view virtual override(IERC6059, IERC721) returns (address) {
        (address owner, uint256 ownerTokenId, bool isNft) = directOwnerOf(
            tokenId
        );
        if (isNft) {
            owner = IERC6059(owner).ownerOf(ownerTokenId);
        }
        return owner;
    }

    /**
     * @inheritdoc IERC6059
     */
    function directOwnerOf(
        uint256 tokenId
    ) public view virtual returns (address, uint256, bool) {
        DirectOwner memory owner = _RMRKOwners[tokenId];
        if (owner.ownerAddress == address(0)) revert ERC721InvalidTokenId();

        return (owner.ownerAddress, owner.tokenId, owner.tokenId != 0);
    }

    ////////////////////////////////////////
    //              BURNING
    ////////////////////////////////////////

    /**
     * @notice Used to burn a given token.
     * @dev In case the token has any child tokens, the execution will be reverted.
     * @param tokenId ID of the token to burn
     */
    function burn(uint256 tokenId) public virtual {
        burn(tokenId, 0);
    }

    /**
     * @inheritdoc IERC6059
     */
    function burn(
        uint256 tokenId,
        uint256 maxChildrenBurns
    ) public virtual onlyApprovedOrDirectOwner(tokenId) returns (uint256) {
        return _burn(tokenId, maxChildrenBurns);
    }

    /**
     * @notice Used to burn a token.
     * @dev When a token is burned, its children are recursively burned as well.
     * @dev The approvals are cleared when the token is burned.
     * @dev Requirements:
     *
     *  - `tokenId` must exist.
     * @dev Emits a {Transfer} event.
     * @dev Emits a {NestTransfer} event.
     * @param tokenId ID of the token to burn
     * @param maxChildrenBurns Maximum children to recursively burn
     * @return The number of recursive burns it took to burn all of the children
     */
    function _burn(
        uint256 tokenId,
        uint256 maxChildrenBurns
    ) internal virtual returns (uint256) {
        (address immediateOwner, uint256 parentId, ) = directOwnerOf(tokenId);
        address owner = ownerOf(tokenId);
        _balances[immediateOwner] -= 1;

        _beforeTokenTransfer(owner, address(0), tokenId);
        _beforeNestedTokenTransfer(
            immediateOwner,
            address(0),
            parentId,
            0,
            tokenId,
            ""
        );

        _approve(address(0), tokenId);
        _cleanApprovals(tokenId);

        Child[] memory children = childrenOf(tokenId);

        delete _activeChildren[tokenId];
        delete _pendingChildren[tokenId];
        delete _tokenApprovals[tokenId][owner];

        uint256 pendingRecursiveBurns;
        uint256 totalChildBurns;

        uint256 length = children.length; //gas savings
        for (uint256 i; i < length; ) {
            if (totalChildBurns >= maxChildrenBurns)
                revert RMRKMaxRecursiveBurnsReached(
                    children[i].contractAddress,
                    children[i].tokenId
                );
            delete _childIsInActive[children[i].contractAddress][
                children[i].tokenId
            ];
            unchecked {
                // At this point we know pendingRecursiveBurns must be at least 1
                pendingRecursiveBurns = maxChildrenBurns - totalChildBurns;
            }
            // We substract one to the next level to count for the token being burned, then add it again on returns
            // This is to allow the behavior of 0 recursive burns meaning only the current token is deleted.
            totalChildBurns +=
                IERC6059(children[i].contractAddress).burn(
                    children[i].tokenId,
                    pendingRecursiveBurns - 1
                ) +
                1;
            unchecked {
                ++i;
            }
        }
        // Can't remove before burning child since child will call back to get root owner
        delete _RMRKOwners[tokenId];

        emit Transfer(owner, address(0), tokenId);
        emit NestTransfer(immediateOwner, address(0), parentId, 0, tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
        _afterNestedTokenTransfer(
            immediateOwner,
            address(0),
            parentId,
            0,
            tokenId,
            ""
        );

        return totalChildBurns;
    }

    ////////////////////////////////////////
    //              APPROVALS
    ////////////////////////////////////////

    /**
     * @notice Used to grant a one-time approval to manage one's token.
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * @dev The approval is cleared when the token is transferred.
     * @dev Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     * @dev Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     * @dev Emits an {Approval} event.
     * @param to Address receiving the approval
     * @param tokenId ID of the token for which the approval is being granted
     */
    function approve(address to, uint256 tokenId) public virtual {
        address owner = ownerOf(tokenId);
        if (to == owner) revert ERC721ApprovalToCurrentOwner();

        if (_msgSender() != owner && !isApprovedForAll(owner, _msgSender()))
            revert ERC721ApproveCallerIsNotOwnerNorApprovedForAll();

        _approve(to, tokenId);
    }

    /**
     * @notice Used to retrieve the account approved to manage given token.
     * @dev Requirements:
     *
     *  - `tokenId` must exist.
     * @param tokenId ID of the token to check for approval
     * @return Address of the account approved to manage the token
     */
    function getApproved(
        uint256 tokenId
    ) public view virtual returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId][ownerOf(tokenId)];
    }

    /**
     * @notice Used to approve or remove `operator` as an operator for the caller.
     * @dev Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     * @dev Requirements:
     *
     * - The `operator` cannot be the caller.
     * @dev Emits an {ApprovalForAll} event.
     * @param operator Address of the operator being managed
     * @param approved A boolean value signifying whether the approval is being granted (`true`) or (`revoked`)
     */
    function setApprovalForAll(address operator, bool approved) public virtual {
        if (_msgSender() == operator) revert ERC721ApproveToCaller();
        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @notice Used to check if the given address is allowed to manage the tokens of the specified address.
     * @param owner Address of the owner of the tokens
     * @param operator Address being checked for approval
     * @return A boolean value signifying whether the *operator* is allowed to manage the tokens of the *owner* (`true`)
     *  or not (`false`)
     */
    function isApprovedForAll(
        address owner,
        address operator
    ) public view virtual returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @notice Used to grant an approval to manage a given token.
     * @dev Emits an {Approval} event.
     * @param to Address to which the approval is being granted
     * @param tokenId ID of the token for which the approval is being granted
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        address owner = ownerOf(tokenId);
        _tokenApprovals[tokenId][owner] = to;
        emit Approval(owner, to, tokenId);
    }

    /**
     * @notice Used to update the owner of the token and clear the approvals associated with the previous owner.
     * @dev The `destinationId` should equal `0` if the new owner is an externally owned account.
     * @param tokenId ID of the token being updated
     * @param destinationId ID of the token to receive the given token
     * @param to Address of account to receive the token
     */
    function _updateOwnerAndClearApprovals(
        uint256 tokenId,
        uint256 destinationId,
        address to
    ) internal {
        _RMRKOwners[tokenId] = DirectOwner({
            ownerAddress: to,
            tokenId: destinationId
        });

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);
        _cleanApprovals(tokenId);
    }

    /**
     * @notice Used to remove approvals for the current owner of the given token.
     * @param tokenId ID of the token to clear the approvals for
     */
    function _cleanApprovals(uint256 tokenId) internal virtual {}

    ////////////////////////////////////////
    //              UTILS
    ////////////////////////////////////////

    /**
     * @notice Used to check whether the given account is allowed to manage the given token.
     * @dev Requirements:
     *
     *  - `tokenId` must exist.
     * @param spender Address that is being checked for approval
     * @param tokenId ID of the token being checked
     * @return A boolean value indicating whether the `spender` is approved to manage the given token
     */
    function _isApprovedOrOwner(
        address spender,
        uint256 tokenId
    ) internal view virtual returns (bool) {
        address owner = ownerOf(tokenId);
        return (spender == owner ||
            isApprovedForAll(owner, spender) ||
            getApproved(tokenId) == spender);
    }

    /**
     * @notice Used to check whether the account is approved to manage the token or its direct owner.
     * @param spender Address that is being checked for approval or direct ownership
     * @param tokenId ID of the token being checked
     * @return A boolean value indicating whether the `spender` is approved to manage the given token or its
     *  direct owner
     */
    function _isApprovedOrDirectOwner(
        address spender,
        uint256 tokenId
    ) internal view virtual returns (bool) {
        (address owner, uint256 parentId, ) = directOwnerOf(tokenId);
        // When the parent is an NFT, only it can do operations
        if (parentId != 0) {
            return (spender == owner);
        }
        // Otherwise, the owner or approved address can
        return (spender == owner ||
            isApprovedForAll(owner, spender) ||
            getApproved(tokenId) == spender);
    }

    /**
     * @notice Used to enforce that the given token has been minted.
     * @dev Reverts if the `tokenId` has not been minted yet.
     * @dev The validation checks whether the owner of a given token is a `0x0` address and considers it not minted if
     *  it is. This means that both tokens that haven't been minted yet as well as the ones that have already been
     *  burned will cause the transaction to be reverted.
     * @param tokenId ID of the token to check
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        if (!_exists(tokenId)) revert ERC721InvalidTokenId();
    }

    /**
     * @notice Used to check whether the given token exists.
     * @dev Tokens start existing when they are minted (`_mint`) and stop existing when they are burned (`_burn`).
     * @param tokenId ID of the token being checked
     * @return A boolean value signifying whether the token exists
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _RMRKOwners[tokenId].ownerAddress != address(0);
    }

    /**
     * @notice Used to invoke {IERC721Receiver-onERC721Received} on a target address.
     * @dev The call is not executed if the target address is not a contract.
     * @param from Address representing the previous owner of the given token
     * @param to Yarget address that will receive the tokens
     * @param tokenId ID of the token to be transferred
     * @param data Optional data to send along with the call
     * @return Boolean value signifying whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try
                IERC721Receiver(to).onERC721Received(
                    _msgSender(),
                    from,
                    tokenId,
                    data
                )
            returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == uint256(0)) {
                    revert ERC721TransferToNonReceiverImplementer();
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    ////////////////////////////////////////
    //      CHILD MANAGEMENT PUBLIC
    ////////////////////////////////////////

    /**
     * @inheritdoc IERC6059
     */
    function addChild(
        uint256 parentId,
        uint256 childId,
        bytes memory data
    ) public virtual {
        _requireMinted(parentId);

        address childAddress = _msgSender();
        if (!childAddress.isContract()) revert RMRKIsNotContract();

        Child memory child = Child({
            contractAddress: childAddress,
            tokenId: childId
        });

        _beforeAddChild(parentId, childAddress, childId, data);

        uint256 length = pendingChildrenOf(parentId).length;

        if (length < 128) {
            _pendingChildren[parentId].push(child);
        } else {
            revert RMRKMaxPendingChildrenReached();
        }

        // Previous length matches the index for the new child
        emit ChildProposed(parentId, length, childAddress, childId);

        _afterAddChild(parentId, childAddress, childId, data);
    }

    /**
     * @inheritdoc IERC6059
     */
    function acceptChild(
        uint256 parentId,
        uint256 childIndex,
        address childAddress,
        uint256 childId
    ) public virtual onlyApprovedOrOwner(parentId) {
        _acceptChild(parentId, childIndex, childAddress, childId);
    }

    /**
     * @notice Used to accept a pending child token for a given parent token.
     * @dev This moves the child token from parent token's pending child tokens array into the active child tokens
     *  array.
     * @dev Requirements:
     *
     *  - `tokenId` must exist
     *  - `index` must be in range of the pending children array
     * @dev Emits ***ChildAccepted*** event.
     * @param parentId ID of the parent token for which the child token is being accepted
     * @param childIndex Index of a child tokem in the given parent's pending children array
     * @param childAddress Address of the collection smart contract of the child token expected to be located at the
     *  specified index of the given parent token's pending children array
     * @param childId ID of the child token expected to be located at the specified index of the given parent token's
     *  pending children array
     */
    function _acceptChild(
        uint256 parentId,
        uint256 childIndex,
        address childAddress,
        uint256 childId
    ) internal virtual {
        Child memory child = pendingChildOf(parentId, childIndex);
        _checkExpectedChild(child, childAddress, childId);
        if (_childIsInActive[childAddress][childId] != 0)
            revert RMRKChildAlreadyExists();

        _beforeAcceptChild(parentId, childIndex, childAddress, childId);

        // Remove from pending:
        _removeChildByIndex(_pendingChildren[parentId], childIndex);

        // Add to active:
        _activeChildren[parentId].push(child);
        _childIsInActive[childAddress][childId] = 1; // We use 1 as true

        emit ChildAccepted(parentId, childIndex, childAddress, childId);

        _afterAcceptChild(parentId, childIndex, childAddress, childId);
    }

    /**
     * @inheritdoc IERC6059
     */
    function rejectAllChildren(
        uint256 tokenId,
        uint256 maxRejections
    ) public virtual onlyApprovedOrOwner(tokenId) {
        _rejectAllChildren(tokenId, maxRejections);
    }

    /**
     * @notice Used to reject all pending children of a given parent token.
     * @dev Removes the children from the pending array mapping.
     * @dev This does not update the ownership storage data on children. If necessary, ownership can be reclaimed by the
     *  rootOwner of the previous parent.
     * @dev Requirements:
     *
     *  - `tokenId` must exist
     * @dev Emits ***AllChildrenRejected*** event.
     * @param tokenId ID of the parent token for which to reject all of the pending tokens.
     * @param maxRejections Maximum number of expected children to reject, used to prevent from rejecting children which
     *  arrive just before this operation.
     */
    function _rejectAllChildren(
        uint256 tokenId,
        uint256 maxRejections
    ) internal virtual {
        if (_pendingChildren[tokenId].length > maxRejections)
            revert RMRKUnexpectedNumberOfChildren();

        _beforeRejectAllChildren(tokenId);
        delete _pendingChildren[tokenId];
        emit AllChildrenRejected(tokenId);
        _afterRejectAllChildren(tokenId);
    }

    /**
     * @inheritdoc IERC6059
     */
    function transferChild(
        uint256 tokenId,
        address to,
        uint256 destinationId,
        uint256 childIndex,
        address childAddress,
        uint256 childId,
        bool isPending,
        bytes memory data
    ) public virtual onlyApprovedOrOwner(tokenId) {
        _transferChild(
            tokenId,
            to,
            destinationId,
            childIndex,
            childAddress,
            childId,
            isPending,
            data
        );
    }

    /**
     * @notice Used to transfer a child token from a given parent token.
     * @dev When transferring a child token, the owner of the token is set to `to`, or is not updated in the event of
     *  `to` being the `0x0` address.
     * @dev Requirements:
     *
     *  - `tokenId` must exist.
     * @dev Emits {ChildTransferred} event.
     * @param tokenId ID of the parent token from which the child token is being transferred
     * @param to Address to which to transfer the token to
     * @param destinationId ID of the token to receive this child token (MUST be 0 if the destination is not a token)
     * @param childIndex Index of a token we are transferring, in the array it belongs to (can be either active array or
     *  pending array)
     * @param childAddress Address of the child token's collection smart contract.
     * @param childId ID of the child token in its own collection smart contract.
     * @param isPending A boolean value indicating whether the child token being transferred is in the pending array of
     *  the parent token (`true`) or in the active array (`false`)
     * @param data Additional data with no specified format, sent in call to `_to`
     */
    function _transferChild(
        uint256 tokenId,
        address to,
        uint256 destinationId, // newParentId
        uint256 childIndex,
        address childAddress,
        uint256 childId,
        bool isPending,
        bytes memory data
    ) internal virtual {
        Child memory child;
        if (isPending) {
            child = pendingChildOf(tokenId, childIndex);
        } else {
            child = childOf(tokenId, childIndex);
        }
        _checkExpectedChild(child, childAddress, childId);

        _beforeTransferChild(
            tokenId,
            childIndex,
            childAddress,
            childId,
            isPending,
            data
        );

        if (isPending) {
            _removeChildByIndex(_pendingChildren[tokenId], childIndex);
        } else {
            delete _childIsInActive[childAddress][childId];
            _removeChildByIndex(_activeChildren[tokenId], childIndex);
        }

        if (to != address(0)) {
            if (destinationId == uint256(0)) {
                IERC721(childAddress).safeTransferFrom(
                    address(this),
                    to,
                    childId,
                    data
                );
            } else {
                // Destination is an NFT
                IERC6059(child.contractAddress).nestTransferFrom(
                    address(this),
                    to,
                    child.tokenId,
                    destinationId,
                    data
                );
            }
        }

        emit ChildTransferred(
            tokenId,
            childIndex,
            childAddress,
            childId,
            isPending,
            to == address(0)
        );
        _afterTransferChild(
            tokenId,
            childIndex,
            childAddress,
            childId,
            isPending,
            data
        );
    }

    /**
     * @notice Used to verify that the child being accessed is the intended child.
     * @dev The Child struct consists of the following values:
     *  [
     *      tokenId,
     *      contractAddress
     *  ]
     * @param child A Child struct of a child being accessed
     * @param expectedAddress The address expected to be the one of the child
     * @param expectedId The token ID expected to be the one of the child
     */
    function _checkExpectedChild(
        Child memory child,
        address expectedAddress,
        uint256 expectedId
    ) private pure {
        if (
            expectedAddress != child.contractAddress ||
            expectedId != child.tokenId
        ) revert RMRKUnexpectedChildId();
    }

    ////////////////////////////////////////
    //      CHILD MANAGEMENT GETTERS
    ////////////////////////////////////////

    /**
     * @inheritdoc IERC6059
     */

    function childrenOf(
        uint256 parentId
    ) public view virtual returns (Child[] memory) {
        Child[] memory children = _activeChildren[parentId];
        return children;
    }

    /**
     * @inheritdoc IERC6059
     */

    function pendingChildrenOf(
        uint256 parentId
    ) public view virtual returns (Child[] memory) {
        Child[] memory pendingChildren = _pendingChildren[parentId];
        return pendingChildren;
    }

    /**
     * @inheritdoc IERC6059
     */
    function childOf(
        uint256 parentId,
        uint256 index
    ) public view virtual returns (Child memory) {
        if (childrenOf(parentId).length <= index)
            revert RMRKChildIndexOutOfRange();
        Child memory child = _activeChildren[parentId][index];
        return child;
    }

    /**
     * @inheritdoc IERC6059
     */
    function pendingChildOf(
        uint256 parentId,
        uint256 index
    ) public view virtual returns (Child memory) {
        if (pendingChildrenOf(parentId).length <= index)
            revert RMRKPendingChildIndexOutOfRange();
        Child memory child = _pendingChildren[parentId][index];
        return child;
    }

    // HOOKS

    /**
     * @notice Hook that is called before nested token transfer.
     * @dev To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     * @param from Address from which the token is being transferred
     * @param to Address to which the token is being transferred
     * @param fromTokenId ID of the token from which the given token is being transferred
     * @param toTokenId ID of the token to which the given token is being transferred
     * @param tokenId ID of the token being transferred
     * @param data Additional data with no specified format, sent in the addChild call
     */
    function _beforeNestedTokenTransfer(
        address from,
        address to,
        uint256 fromTokenId,
        uint256 toTokenId,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {}

    /**
     * @notice Hook that is called after nested token transfer.
     * @dev To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     * @param from Address from which the token was transferred
     * @param to Address to which the token was transferred
     * @param fromTokenId ID of the token from which the given token was transferred
     * @param toTokenId ID of the token to which the given token was transferred
     * @param tokenId ID of the token that was transferred
     * @param data Additional data with no specified format, sent in the addChild call
     */
    function _afterNestedTokenTransfer(
        address from,
        address to,
        uint256 fromTokenId,
        uint256 toTokenId,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {}

    /**
     * @notice Hook that is called before a child is added to the pending tokens array of a given token.
     * @dev The Child struct consists of the following values:
     *  [
     *      tokenId,
     *      contractAddress
     *  ]
     * @dev To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     * @param tokenId ID of the token that will receive a new pending child token
     * @param childAddress Address of the collection smart contract of the child token expected to be located at the
     *  specified index of the given parent token's pending children array
     * @param childId ID of the child token expected to be located at the specified index of the given parent token's
     *  pending children array
     * @param data Additional data with no specified format
     */
    function _beforeAddChild(
        uint256 tokenId,
        address childAddress,
        uint256 childId,
        bytes memory data
    ) internal virtual {}

    /**
     * @notice Hook that is called after a child is added to the pending tokens array of a given token.
     * @dev The Child struct consists of the following values:
     *  [
     *      tokenId,
     *      contractAddress
     *  ]
     * @dev To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     * @param tokenId ID of the token that has received a new pending child token
     * @param childAddress Address of the collection smart contract of the child token expected to be located at the
     *  specified index of the given parent token's pending children array
     * @param childId ID of the child token expected to be located at the specified index of the given parent token's
     *  pending children array
     * @param data Additional data with no specified format
     */
    function _afterAddChild(
        uint256 tokenId,
        address childAddress,
        uint256 childId,
        bytes memory data
    ) internal virtual {}

    /**
     * @notice Hook that is called before a child is accepted to the active tokens array of a given token.
     * @dev The Child struct consists of the following values:
     *  [
     *      tokenId,
     *      contractAddress
     *  ]
     * @dev To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     * @param parentId ID of the token that will accept a pending child token
     * @param childIndex Index of the child token to accept in the given parent token's pending children array
     * @param childAddress Address of the collection smart contract of the child token expected to be located at the
     *  specified index of the given parent token's pending children array
     * @param childId ID of the child token expected to be located at the specified index of the given parent token's
     *  pending children array
     */
    function _beforeAcceptChild(
        uint256 parentId,
        uint256 childIndex,
        address childAddress,
        uint256 childId
    ) internal virtual {}

    /**
     * @notice Hook that is called after a child is accepted to the active tokens array of a given token.
     * @dev The Child struct consists of the following values:
     *  [
     *      tokenId,
     *      contractAddress
     *  ]
     * @dev To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     * @param parentId ID of the token that has accepted a pending child token
     * @param childIndex Index of the child token that was accpeted in the given parent token's pending children array
     * @param childAddress Address of the collection smart contract of the child token that was expected to be located
     *  at the specified index of the given parent token's pending children array
     * @param childId ID of the child token that was expected to be located at the specified index of the given parent
     *  token's pending children array
     */
    function _afterAcceptChild(
        uint256 parentId,
        uint256 childIndex,
        address childAddress,
        uint256 childId
    ) internal virtual {}

    /**
     * @notice Hook that is called before a child is transferred from a given child token array of a given token.
     * @dev The Child struct consists of the following values:
     *  [
     *      tokenId,
     *      contractAddress
     *  ]
     * @dev To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     * @param tokenId ID of the token that will transfer a child token
     * @param childIndex Index of the child token that will be transferred from the given parent token's children array
     * @param childAddress Address of the collection smart contract of the child token that is expected to be located
     *  at the specified index of the given parent token's children array
     * @param childId ID of the child token that is expected to be located at the specified index of the given parent
     *  token's children array
     * @param isPending A boolean value signifying whether the child token is being transferred from the pending child
     *  tokens array (`true`) or from the active child tokens array (`false`)
     * @param data Additional data with no specified format, sent in the addChild call
     */
    function _beforeTransferChild(
        uint256 tokenId,
        uint256 childIndex,
        address childAddress,
        uint256 childId,
        bool isPending,
        bytes memory data
    ) internal virtual {}

    /**
     * @notice Hook that is called after a child is transferred from a given child token array of a given token.
     * @dev The Child struct consists of the following values:
     *  [
     *      tokenId,
     *      contractAddress
     *  ]
     * @dev To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     * @param tokenId ID of the token that has transferred a child token
     * @param childIndex Index of the child token that was transferred from the given parent token's children array
     * @param childAddress Address of the collection smart contract of the child token that was expected to be located
     *  at the specified index of the given parent token's children array
     * @param childId ID of the child token that was expected to be located at the specified index of the given parent
     *  token's children array
     * @param isPending A boolean value signifying whether the child token was transferred from the pending child tokens
     *  array (`true`) or from the active child tokens array (`false`)
     * @param data Additional data with no specified format, sent in the addChild call
     */
    function _afterTransferChild(
        uint256 tokenId,
        uint256 childIndex,
        address childAddress,
        uint256 childId,
        bool isPending,
        bytes memory data
    ) internal virtual {}

    /**
     * @notice Hook that is called before a pending child tokens array of a given token is cleared.
     * @dev To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     * @param tokenId ID of the token that will reject all of the pending child tokens
     */
    function _beforeRejectAllChildren(uint256 tokenId) internal virtual {}

    /**
     * @notice Hook that is called after a pending child tokens array of a given token is cleared.
     * @dev To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     * @param tokenId ID of the token that has rejected all of the pending child tokens
     */
    function _afterRejectAllChildren(uint256 tokenId) internal virtual {}

    // HELPERS

    /**
     * @notice Used to remove a specified child token form an array using its index within said array.
     * @dev The caller must ensure that the length of the array is valid compared to the index passed.
     * @dev The Child struct consists of the following values:
     *  [
     *      tokenId,
     *      contractAddress
     *  ]
     * @param array An array od Child struct containing info about the child tokens in a given child tokens array
     * @param index An index of the child token to remove in the accompanying array
     */
    function _removeChildByIndex(Child[] storage array, uint256 index) private {
        array[index] = array[array.length - 1];
        array.pop();
    }
}