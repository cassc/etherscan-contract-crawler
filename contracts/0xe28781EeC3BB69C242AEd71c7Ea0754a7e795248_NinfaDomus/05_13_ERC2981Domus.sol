/*----------------------------------------------------------*|
|*          ███    ██ ██ ███    ██ ███████  █████           *|
|*          ████   ██ ██ ████   ██ ██      ██   ██          *|
|*          ██ ██  ██ ██ ██ ██  ██ █████   ███████          *|
|*          ██  ██ ██ ██ ██  ██ ██ ██      ██   ██          *|
|*          ██   ████ ██ ██   ████ ██      ██   ██          *|
|*----------------------------------------------------------*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/*************************************************************
 * @title ERC2981Communal                                    *
 *                                                           *
 * @notice Adds ERC-2981 support to {ERC1155}                *
 *                                                           *
 * @dev {ERC2981} royalties for communal collections         *
 *                                                           *
 * @custom:security-contact [email protected]                    *
 ************************************************************/

 contract ERC2981Domus {
    /**
     * @notice `_royaltyRecipients` maps token ID to original artist, used for sending royalties to _royaltyRecipients on all secondary sales.
     *      This is meant for communal editions; in self-sovreign editions there is a single contract-wide royalty recipient
     * @dev "If you plan on having a contract where NFTs are created by multiple authors AND they can update royalty details after minting,
     *      you will need to record the original author of each token." - https://forum.openzeppelin.com/t/setting-erc2981/16065/2
     */
    mapping(uint256 => address) private _royaltyRecipients;
    /**
     * @dev `_minters`
     *      > "If you plan on having a contract where NFTs are created by multiple authors
     *      AND they can update royalty details after minting, you will need to record the original author of each token." - https://forum.openzeppelin.com/t/setting-erc2981/16065/2
     *      i.e. the original artist's address if different from the royalty recipient's address, MUST be stored in order to be used for access control on setter functions
     */
    mapping(uint256 => address) private _minters; // tokenId to original creator address
    /// @dev "For precision purposes, it's better to express the royalty percentage as "basis points" (points per 10_000, e.g., 10% = 1000 bps) and compute the amount is `(royaltyBps[_tokenId] * _salePrice) / 10000`" - https://forum.openzeppelin.com/t/setting-erc2981/16065/2
    uint24 internal constant ROYALTY_BPS = 1000; // 10% fixed royalties
    uint24 private constant TOTAL_SHARES = 10000; // 10,000 = 100% (total sale price)

    /**
     * @notice Called with the sale price to determine how much royalty
     *          is owed and to whom.
     * @param _tokenId - the NFT asset queried for royalty information
     * @param _salePrice - the sale price of the NFT asset specified by _tokenId
     * @return recipient - address of who should be sent the royalty payment
     * @return royaltyAmount - the royalty payment amount for _salePrice
     */
    function royaltyInfo(
        uint256 _tokenId,
        uint256 _salePrice
    ) external view returns (address recipient, uint256 royaltyAmount) {
        recipient = _royaltyRecipients[_tokenId];
        royaltyAmount = (_salePrice * ROYALTY_BPS) / TOTAL_SHARES;
    }

    /**
     * @notice This function is used when the artist decides to set the royalty recipient to an address other than its own.
     * It adds the artist address to the `_minters` mapping in {ERC2981Communal}, in order to use it for access control in `setRoyaltyRecipient()`. This removes the burden of setting this mapping in the `mint()` function as it will rarely be needed.
     * @param _royaltyRecipient (likely a payment splitter contract) may be 0x0 although it is not intended as ETH would be burnt if sent to 0x0. If the user only wants to mint it should call mint() instead, so that the roy
     *
     * Require:
     *
     * - If the `_minters` for `_tokenId` mapping is empty, the minter's address is equal to `_royaltyRecipients[_tokenId]`. I.e. the caller must correspond to `_royaltyRecipients[_tokenId]`, i.e. the token minter/artist
     * - Else, the caller must correspond to the `_tokenId`'s minter address set in `_minters[_tokenId]`, i.e. if `_minters[_tokenId]` is not 0x0. Note that the artist address cannot be reset.
     *
     * Allow:
     *
     * - the minter may (re)set `_royaltyRecipients[_tokenId]` to the same address as `_minters[_tokenId]`, i.e. the minter/artist. This would be quite useless, but not dangerous. The frontend should disallow it.
     *
     */
    function setRoyaltyRecipient(
        address _royaltyRecipient,
        uint256 _tokenId
    ) external {
        if (_minters[_tokenId] == address(0)) {
            require(msg.sender == _royaltyRecipients[_tokenId]); // require that the token has already been minted and that the caller is the minter
            _minters[_tokenId] = msg.sender;
        } else {
            require(msg.sender == _minters[_tokenId]);
        }

        _royaltyRecipients[_tokenId] =(_royaltyRecipient);
    }

    function _setRoyaltyRecipient(
        address _royaltyRecipient,
        uint256 _tokenId
    ) internal {
        _royaltyRecipients[_tokenId] = (_royaltyRecipient);
    }

    function _resetTokenRoyalty(uint256 _tokenId) internal {
        delete _royaltyRecipients[_tokenId];
        delete _minters[_tokenId];
    }

}