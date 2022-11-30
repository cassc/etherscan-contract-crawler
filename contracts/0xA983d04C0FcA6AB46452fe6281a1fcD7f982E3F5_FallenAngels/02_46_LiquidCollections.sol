// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@thirdweb-dev/contracts/base/ERC721Drop.sol";
import "@thirdweb-dev/contracts/eip/interface/IERC721Enumerable.sol";
import "@thirdweb-dev/contracts/extension/Drop.sol";
import "@thirdweb-dev/contracts/extension/DefaultOperatorFilterer.sol";

contract LiquidCollections is
    IERC721Enumerable,
    ERC721Drop,
    DefaultOperatorFilterer
{
    constructor(
        string memory _name,
        string memory _symbol,
        address _royaltyRecipient,
        uint128 _royaltyBps,
        address _primarySaleRecipient
    )
        ERC721Drop(
            _name,
            _symbol,
            _royaltyRecipient,
            _royaltyBps,
            _primarySaleRecipient
        )
    {}

    // // copy-pasted from DropSinglePhase.sol
    // function canClaim(
    //     address _receiver,
    //     uint256 _quantity,
    //     address _currency,
    //     uint256 _pricePerToken,
    //     AllowlistProof calldata _allowlistProof,
    //     bytes memory _data
    // ) public view {
    //     _beforeClaim(
    //         _receiver,
    //         _quantity,
    //         _currency,
    //         _pricePerToken,
    //         _allowlistProof,
    //         _data
    //     );

    //     // bytes32 activeConditionId = conditionId;

    //     /**
    //      *  We make allowlist checks (i.e. verifyClaimMerkleProof) before verifying the claim's general
    //      *  validity (i.e. verifyClaim) because we give precedence to the check of allow list quantity
    //      *  restriction over the check of the general claim condition's quantityLimitPerTransaction
    //      *  restriction.
    //      */

    //     // Verify inclusion in allowlist.
    //     (
    //         bool validMerkleProof,
    //         uint256 merkleProofIndex
    //     ) = verifyClaimMerkleProof(
    //             _dropMsgSender(),
    //             _quantity,
    //             _allowlistProof
    //         );

    //     // Verify claim validity. If not valid, revert.
    //     // when there's allowlist present --> verifyClaimMerkleProof will verify the maxQuantityInAllowlist value with hashed leaf in the allowlist
    //     // when there's no allowlist, this check is true --> verifyClaim will check for _quantity being equal/less than the limit
    //     bool toVerifyMaxQuantityPerTransaction = _allowlistProof
    //         .maxQuantityInAllowlist ==
    //         0 ||
    //         claimCondition.merkleRoot == bytes32(0);

    //     verifyClaim(
    //         _dropMsgSender(),
    //         _quantity,
    //         _currency,
    //         _pricePerToken,
    //         toVerifyMaxQuantityPerTransaction
    //     );
    // }

    function setApprovalForAll(address operator, bool approved)
        public
        override
    {
        super.setApprovalForAll(operator, approved);
    }

    // function approve(address operator, uint256 tokenId) public override {
    //     super.approve(operator, tokenId);
    // }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    /////////////////////
    // redemption
    /////////////////////
    mapping(uint256 => bool) private redeemed;

    event Redeem(address indexed from, uint256 indexed tokenId);

    function isRedeemable(uint256 tokenId) public view virtual returns (bool) {
        require(_exists(tokenId), "LiquidCollections: Token does not exist");
        return !redeemed[tokenId];
    }

    function redeem(uint256 tokenId) public virtual {
        require(_exists(tokenId), "LiquidCollections: Token does not exist");
        require(
            ownerOf(tokenId) == msg.sender,
            "LiquidCollections: You are not the owner of this token"
        );
        require(
            redeemed[tokenId] == false,
            "LiquidCollections: NFT is aleady redeemed"
        );

        redeemed[tokenId] = true;

        emit Redeem(msg.sender, tokenId);
    }

    struct Redeemey {
        uint256 id;
        string tokenURI;
        bool redeemed;
    }

    function getMineWithMetadata(address _owner)
        public
        view
        returns (Redeemey[] memory)
    {
        // address _owner = msg.sender;
        uint256 lngth = ERC721A.balanceOf(_owner);
        Redeemey[] memory _metadatasOfOwners = new Redeemey[](lngth);

        uint256 i;
        for (i = 0; i < lngth; i++) {
            uint256 tUid = tokenOfOwnerByIndex(_owner, i);

            _metadatasOfOwners[i] = Redeemey({
                id: tUid,
                redeemed: redeemed[tUid],
                tokenURI: tokenURI(tUid)
            });
        }

        return (_metadatasOfOwners);
    }

    /////////////////////
    // enumerability
    /////////////////////
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            index < ERC721A.balanceOf(owner),
            "ERC721Enumerable: owner index out of bounds"
        );
        return _ownedTokens[owner][index];
    }

    // /**
    //  * @dev See {IERC721Enumerable-totalSupply}.
    //  */
    // function totalSupply() public view virtual override returns (uint256) {
    //     return _allTokens.length;
    // }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            index < ERC721A.totalSupply(),
            "ERC721Enumerable: global index out of bounds"
        );
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and 'to' cannot be the zero address at the same time.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 tokenId,
        uint256 quantity
    ) internal virtual override {
        // super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    // /**
    //  * @dev Hook that is called before any batch token transfer. For now this is limited
    //  * to batch minting by the {ERC721Consecutive} extension.
    //  *
    //  * Calling conditions:
    //  *
    //  * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
    //  * transferred to `to`.
    //  * - When `from` is zero, `tokenId` will be minted for `to`.
    //  * - When `to` is zero, ``from``'s `tokenId` will be burned.
    //  * - `from` cannot be the zero address.
    //  * - `to` cannot be the zero address.
    //  *
    //  * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
    //  */
    // function _beforeConsecutiveTokenTransfer(
    //     address,
    //     address,
    //     uint256,
    //     uint96
    // ) internal virtual override {
    //     revert("ERC721Enumerable: consecutive transfers not supported");
    // }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721A.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId)
        private
    {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721A.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}