// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Copyright (C) 2022 Spanning Labs Inc.

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

import "../../ISpanningDelegate.sol";
import "./ISpanningERC721.sol";
import "../../SpanningUtils.sol";
import "../../Spanning.sol";

/**
 * @dev Implementation of the {ISpanningERC721} interface.
 */
abstract contract SpanningERC721 is
    Spanning,
    Context,
    ERC165,
    ISpanningERC721,
    IERC721Metadata
{
    // This allows us to efficiently unpack data in our address specification.
    using SpanningAddress for bytes32;

    using Address for address;
    using Strings for uint256;

    // Standard metadata: token name
    string private name_;

    // Standard metadata: token symbol
    string private symbol_;

    // Mapping from token ID to owner address
    mapping(uint256 => bytes32) private owners_;

    // Mapping owner address to token count
    mapping(bytes32 => uint256) private balances_;

    // Mapping from token ID to approved address
    mapping(uint256 => bytes32) private tokenApprovals_;

    // Mapping from sender to receiver approvals
    mapping(bytes32 => mapping(bytes32 => bool)) private operatorApprovals_;

    // Convenience modifier for common bounds checks
    modifier onlyOwnerOrApproved(uint256 tokenId) {
        require(
            _isApprovedOrOwner(spanningMsgSender(), tokenId),
            "onlyOwnerOrApproved: bad role"
        );
        _;
    }

    /**
     * @dev Creates the instance and assigns required values.
     *
     * @param nameIn - Desired name for the token collection
     * @param symbolIn - Desired symbol for the token collection
     * @param delegate - Legacy (local) address for the Spanning Delegate
     */
    constructor(
        string memory nameIn,
        string memory symbolIn,
        address delegate
    ) Spanning(delegate) {
        name_ = nameIn;
        symbol_ = symbolIn;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address accountLegacyAddress)
        public
        view
        virtual
        override
        returns (uint256)
    {
        bytes32 accountAddress = getAddressFromLegacy(accountLegacyAddress);
        return balanceOf(accountAddress);
    }

    /**
     * @dev Returns the number of tokens owned by an account.
     *
     * @param accountAddress - Address to be queried
     *
     * @return uint256 - Number of tokens owned by an account
     */
    function balanceOf(bytes32 accountAddress)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            accountAddress.valid(),
            "ERC721: balance query for the invalid address"
        );
        return balances_[accountAddress];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        bytes32 ownerAddress = ownerOfSpanning(tokenId);
        // To prevent incorrect data leakage, we return the legacy address
        // only if that user is local to the current domain.
        bytes4 ownerDomain = getDomainFromAddress(ownerAddress);
        require(
            ownerDomain == getDomain(),
            "ERC721: remote account requesting legacy address"
        );
        return getLegacyFromAddress(ownerAddress);
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOfSpanning(uint256 tokenId)
        public
        view
        virtual
        override
        returns (bytes32)
    {
        bytes32 ownerAddress = owners_[tokenId];
        require(
            ownerAddress.valid(),
            "ERC721: owner query for nonexistent token"
        );
        return ownerAddress;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return name_;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return symbol_;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString()))
                : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address receiverLegacyAddress, uint256 tokenId)
        public
        virtual
        override
    {
        bytes32 receiverAddress = getAddressFromLegacy(receiverLegacyAddress);
        approve(receiverAddress, tokenId);
    }

    /**
     * @dev Sets a token allowance for a pair of addresses (sender and receiver).
     *
     * @param receiverAddress - Address of the allowance receiver
     * @param tokenId - Token allowance to be approved
     */
    function approve(bytes32 receiverAddress, uint256 tokenId)
        public
        virtual
        override
        onlyOwnerOrApproved(tokenId)
    {
        bytes32 tokenOwner = SpanningERC721.ownerOfSpanning(tokenId);
        require(
            receiverAddress != tokenOwner,
            "ERC721: approval to current owner"
        );
        _approve(receiverAddress, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        bytes32 ownerAddress = getApprovedSpanning(tokenId);
        // To prevent incorrect data leakage, we return the legacy address
        // only if that user is local to the current domain.
        bytes4 ownerDomain = getDomainFromAddress(ownerAddress);
        require(
            ownerDomain == getDomain(),
            "ERC721: remote account requesting legacy address"
        );
        return getLegacyFromAddress(ownerAddress);
    }

    function getApprovedSpanning(uint256 tokenId)
        public
        view
        virtual
        override
        returns (bytes32)
    {
        require(
            _exists(tokenId),
            "ERC721: approved query for nonexistent token"
        );

        return tokenApprovals_[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(
        address receiverLegacyAddress,
        bool shouldApprove
    ) public virtual override {
        bytes32 receiverAddress = getAddressFromLegacy(receiverLegacyAddress);
        setApprovalForAll(receiverAddress, shouldApprove);
    }

    /**
     * @dev Allows an account to have control over another account's tokens.
     *
     * @param receiverAddress - Address of the allowance receiver (gains control)
     * @param shouldApprove - Whether to approve or revoke the approval
     */
    function setApprovalForAll(bytes32 receiverAddress, bool shouldApprove)
        public
        virtual
        override
    {
        _setApprovalForAll(receiverAddress, shouldApprove);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(
        address senderLegacyAddress,
        address receiverLegacyAddress
    ) public view virtual override returns (bool) {
        bytes32 senderAddress = getAddressFromLegacy(senderLegacyAddress);
        bytes32 receiverAddress = getAddressFromLegacy(receiverLegacyAddress);
        return isApprovedForAll(senderAddress, receiverAddress);
    }

    /**
     * @dev Indicates if an account has total control over another's assets.
     *
     * @param senderAddress - Address of the allowance sender (cede control)
     * @param receiverAddress - Address of the allowance receiver (gains control)
     *
     * @return bool - Indicates whether the account is approved for all
     */
    function isApprovedForAll(bytes32 senderAddress, bytes32 receiverAddress)
        public
        view
        virtual
        override
        returns (bool)
    {
        return operatorApprovals_[senderAddress][receiverAddress];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address senderLegacyAddress,
        address receiverLegacyAddress,
        uint256 tokenId
    ) public virtual override {
        bytes32 senderAddress = getAddressFromLegacy(senderLegacyAddress);
        bytes32 receiverAddress = getAddressFromLegacy(receiverLegacyAddress);
        transferFrom(senderAddress, receiverAddress, tokenId);
    }

    /**
     * @dev Moves requested tokens between accounts.
     *
     * @param senderAddress - Address of the sender
     * @param receiverAddress - Address of the receiver
     * @param tokenId - Token to be transferred
     */
    function transferFrom(
        bytes32 senderAddress,
        bytes32 receiverAddress,
        uint256 tokenId
    ) public virtual override onlyOwnerOrApproved(tokenId) {
        _transfer(senderAddress, receiverAddress, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address senderLegacyAddress,
        address receiverLegacyAddress,
        uint256 tokenId
    ) public virtual override {
        bytes32 senderAddress = getAddressFromLegacy(senderLegacyAddress);
        bytes32 receiverAddress = getAddressFromLegacy(receiverLegacyAddress);
        safeTransferFrom(senderAddress, receiverAddress, tokenId, "");
    }

    /**
     * @dev Safely moves requested tokens between accounts.
     *
     * @param senderAddress - Address of the sender
     * @param receiverAddress - Address of the receiver
     * @param tokenId - Token to be transferred
     */
    function safeTransferFrom(
        bytes32 senderAddress,
        bytes32 receiverAddress,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(senderAddress, receiverAddress, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address senderLegacyAddress,
        address receiverLegacyAddress,
        uint256 tokenId,
        bytes memory payload
    ) public virtual override {
        bytes32 senderAddress = getAddressFromLegacy(senderLegacyAddress);
        bytes32 receiverAddress = getAddressFromLegacy(receiverLegacyAddress);
        safeTransferFrom(senderAddress, receiverAddress, tokenId, payload);
    }

    /**
     * @dev Safely moves requested tokens between accounts, including data.
     *
     * @param senderAddress - Address of the sender
     * @param receiverAddress - Address of the receiver
     * @param tokenId - Token to be transferred
     * @param payload - Additional, unstructured data to be included
     */
    function safeTransferFrom(
        bytes32 senderAddress,
        bytes32 receiverAddress,
        uint256 tokenId,
        bytes memory payload
    ) public virtual override onlyOwnerOrApproved(tokenId) {
        _safeTransfer(senderAddress, receiverAddress, tokenId, payload);
    }

    /**
     * @dev Safely transfers a token between accounts, checking for ERC721 validity.
     *
     * @param senderAddress - Address of the sender
     * @param receiverAddress - Address of the receiver
     * @param tokenId - Token to be transferred
     * @param payload - Additional, unstructured data to be included
     */
    function _safeTransfer(
        bytes32 senderAddress,
        bytes32 receiverAddress,
        uint256 tokenId,
        bytes memory payload
    ) internal virtual {
        _transfer(senderAddress, receiverAddress, tokenId);
        require(
            _checkOnERC721Received(
                senderAddress,
                receiverAddress,
                tokenId,
                payload
            ),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Checks if the token exists (has been minted but not burned).
     *
     * @param tokenId - Token to be checked
     *
     * @return bool - Whether the token exists
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return owners_[tokenId].valid();
    }

    /**
     * @dev Checks if the account is authorized to spend the token.
     *
     * @param receiverAddress - Address of the receiver
     * @param tokenId - Token to be checked
     *
     * @return bool - Whether the account is authorized to spend the token
     */
    function _isApprovedOrOwner(bytes32 receiverAddress, uint256 tokenId)
        internal
        view
        virtual
        returns (bool)
    {
        require(
            _exists(tokenId),
            "ERC721: operator query for nonexistent token"
        );
        bytes32 tokenOwner = SpanningERC721.ownerOfSpanning(tokenId);
        return (receiverAddress == tokenOwner ||
            isApprovedForAll(tokenOwner, receiverAddress) ||
            getApprovedSpanning(tokenId) == receiverAddress);
    }

    /**
     * @dev Safely mints a new token to an account
     *
     * @param receiverAddress - Address of the receiver
     * @param tokenId - Token to be minted
     */
    function _safeMint(bytes32 receiverAddress, uint256 tokenId)
        internal
        virtual
    {
        _safeMint(receiverAddress, tokenId, "");
    }

    /**
     * @dev Safely mints a new token to an account
     *
     * @param receiverAddress - Address of the receiver
     * @param tokenId - Token to be minted
     * @param payload - Additional, unstructured data to be included
     */
    function _safeMint(
        bytes32 receiverAddress,
        uint256 tokenId,
        bytes memory payload
    ) internal virtual {
        _mint(receiverAddress, tokenId);
        require(
            _checkOnERC721Received(
                SpanningAddress.invalidAddress(),
                receiverAddress,
                tokenId,
                payload
            ),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints a new token to an account
     *
     * @param receiverAddress - Address of the receiver
     * @param tokenId - Token to be minted
     */
    function _mint(bytes32 receiverAddress, uint256 tokenId) internal virtual {
        require(receiverAddress.valid(), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(
            SpanningAddress.invalidAddress(),
            receiverAddress,
            tokenId
        );

        balances_[receiverAddress] += 1;
        owners_[tokenId] = receiverAddress;

        emit SpanningTransfer(
            SpanningAddress.invalidAddress(),
            receiverAddress,
            tokenId
        );
        emit Transfer(
            address(0),
            getLegacyFromAddress(receiverAddress),
            tokenId
        );

        _afterTokenTransfer(
            SpanningAddress.invalidAddress(),
            receiverAddress,
            tokenId
        );
    }

    /**
     * @dev Burns the token
     *
     * @param tokenId - Token to be burned
     */
    function _burn(uint256 tokenId) internal virtual {
        bytes32 tokenOwner = SpanningERC721.ownerOfSpanning(tokenId);

        _beforeTokenTransfer(
            tokenOwner,
            SpanningAddress.invalidAddress(),
            tokenId
        );

        // Clear approvals
        _approve(SpanningAddress.invalidAddress(), tokenId);

        balances_[tokenOwner] -= 1;
        delete owners_[tokenId];

        emit SpanningTransfer(
            tokenOwner,
            SpanningAddress.invalidAddress(),
            tokenId
        );
        emit Transfer(getLegacyFromAddress(tokenOwner), address(0), tokenId);

        _afterTokenTransfer(
            tokenOwner,
            SpanningAddress.invalidAddress(),
            tokenId
        );
    }

    /**
     * @dev Transfers the token between accounts
     *
     * @param senderAddress - Address of the sender
     * @param receiverAddress - Address of the receiver
     * @param tokenId - Token to be transferred
     */
    function _transfer(
        bytes32 senderAddress,
        bytes32 receiverAddress,
        uint256 tokenId
    ) internal virtual {
        require(
            SpanningERC721.ownerOfSpanning(tokenId).equals(senderAddress),
            "ERC721: transfer from incorrect owner"
        );
        require(
            receiverAddress.valid(),
            "ERC721: transfer to the zero address"
        );

        _beforeTokenTransfer(senderAddress, receiverAddress, tokenId);

        // Clear approvals from the previous owner
        _approve(SpanningAddress.invalidAddress(), tokenId);

        balances_[senderAddress] -= 1;
        balances_[receiverAddress] += 1;
        owners_[tokenId] = receiverAddress;

        emit Transfer(
            getLegacyFromAddress(senderAddress),
            getLegacyFromAddress(receiverAddress),
            tokenId
        );
        emit SpanningTransfer(senderAddress, receiverAddress, tokenId);

        _afterTokenTransfer(senderAddress, receiverAddress, tokenId);
    }

    /**
     * @dev Sets a token allowance for a pair of addresses (sender and receiver).
     *
     * @param receiverAddress - Address of the allowance receiver
     * @param tokenId - Token allowance to be approved
     */
    function _approve(bytes32 receiverAddress, uint256 tokenId)
        internal
        virtual
    {
        tokenApprovals_[tokenId] = receiverAddress;
        bytes32 owner = SpanningERC721.ownerOfSpanning(tokenId);
        emit Approval(
            getLegacyFromAddress(owner),
            getLegacyFromAddress(receiverAddress),
            tokenId
        );
        emit SpanningApproval(owner, receiverAddress, tokenId);
    }

    /**
     * @dev Allows an account to have control over another account's tokens.
     *
     * @param receiverAddress - Address of the allowance receiver (gains control)
     * @param shouldApprove - Whether to approve or revoke the approval
     */
    function _setApprovalForAll(bytes32 receiverAddress, bool shouldApprove)
        internal
        virtual
    {
        require(
            !spanningMsgSender().equals(receiverAddress),
            "ERC721: approve to caller"
        );
        operatorApprovals_[spanningMsgSender()][
            receiverAddress
        ] = shouldApprove;
        emit ApprovalForAll(
            getLegacyFromAddress(spanningMsgSender()),
            getLegacyFromAddress(receiverAddress),
            shouldApprove
        );
        emit SpanningApprovalForAll(
            spanningMsgSender(),
            receiverAddress,
            shouldApprove
        );
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param senderAddress - Address of the sender
     * @param receiverAddress - Address of the receiver
     * @param tokenId - Token to be transferred
     * @param payload - Additional, unstructured data to be included
     *
     * @return bool - If call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        bytes32 senderAddress,
        bytes32 receiverAddress,
        uint256 tokenId,
        bytes memory payload
    ) private returns (bool) {
        address senderLegacyAddress = getLegacyFromAddress(senderAddress);
        address receiverLegacyAddress = getLegacyFromAddress(receiverAddress);

        // Only dispatch if the destination is a contract and also on the same domain
        if (
            receiverLegacyAddress.isContract() &&
            getDomainFromAddress(receiverAddress) == getDomain()
        ) {
            // TODO(jade) Implement SpanningERC721Receiver
            // https://linear.app/spanninglabs/issue/ENG-135/implement-spanningerc721receiver-for-safe-transfers
            try
                IERC721Receiver(receiverLegacyAddress).onERC721Received(
                    getLegacyFromAddress(spanningMsgSender()),
                    senderLegacyAddress,
                    tokenId,
                    payload
                )
            returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert(
                        "ERC721: transfer to non ERC721Receiver implementer"
                    );
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

    /**
     * @dev Hook that is called before any transfer of tokens.
     *
     * @param senderAddress - Address initiating the transfer
     * @param receiverAddress - Address receiving the transfer
     * @param tokenId - Token to be transferred
     */
    function _beforeTokenTransfer(
        bytes32 senderAddress,
        bytes32 receiverAddress,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any burn of tokens.
     *
     * @param senderAddress - Address sending tokens to burn
     * @param receiverAddress - Unused
     * @param tokenId - Token to be burned
     */
    function _afterTokenTransfer(
        bytes32 senderAddress,
        bytes32 receiverAddress,
        uint256 tokenId
    ) internal virtual {}
}