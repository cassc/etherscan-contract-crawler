/*----------------------------------------------------------*|
|*          ███    ██ ██ ███    ██ ███████  █████           *|
|*          ████   ██ ██ ████   ██ ██      ██   ██          *|
|*          ██ ██  ██ ██ ██ ██  ██ █████   ███████          *|
|*          ██  ██ ██ ██ ██  ██ ██ ██      ██   ██          *|
|*          ██   ████ ██ ██   ████ ██      ██   ██          *|
|*----------------------------------------------------------*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/*************************************************************
 * @title ERC2981NSovreign                                    *
 *                                                           *
 * @notice adds ERC2981 support to ERC-721.                  *
 *                                                           *
 * @dev Royalties BPS and recipient are token level        *
 * and may be set by owner in child contract by writing      *
 * directly to internal storage variables                    *
 *                                                           *
 * @dev Royalty information can be specified globally for    *
 * all token ids via {ERC2981-_setDefaultRoyalty}, and/or    *
 * individually for specific token ids via                   *
 * {ERC2981-_setTokenRoyalty}. The latter takes precedence.  *
 *                                                           *
 * @custom:security-contact [email protected]                    *
 ************************************************************/

contract ERC2981NSovreign {
    struct Recipient {
        address recipient;
        uint24 bps;
    }

    struct RoyaltyInfoArray {
        address[] recipients;
        uint24[] bps;
        uint24 royaltyBps;
    }
    /**
     * @notice `royaltyRecipients` maps token ID to original artist, used for sending royalties to royaltyRecipients on all secondary sales.
     *      In self-sovreign editions there are token level royalty recipients
     * @dev "If you plan on having a contract where NFTs are created by multiple authors AND they can update royalty details after minting,
     *      you will need to record the original author of each token." - https://forum.openzeppelin.com/t/setting-erc2981/16065/2
     */

    mapping(uint256 => RoyaltyInfoArray) private _royaltyInfoArray;

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
        recipient = _royaltyInfoArray[_tokenId].recipients[0];
        royaltyAmount =
            (_salePrice * _royaltyInfoArray[_tokenId].royaltyBps) /
            TOTAL_SHARES;
    }

    function getRecipients(
        uint256 _tokenId
    ) external view returns (Recipient[] memory) {
        uint24[] memory _bps = _royaltyInfoArray[_tokenId].bps;
        address[] memory _recipients = _royaltyInfoArray[_tokenId].recipients;

        uint256 i = _recipients.length;

        Recipient[] memory _royaltyInfo = new Recipient[](i);

        do {
            --i;
            _royaltyInfo[i].recipient = _recipients[i];
            _royaltyInfo[i].bps = _bps[i];
        } while (i > 0);

        return _royaltyInfo;
    }

    /**
     * @notice Called with the sale price to determine how much royalty
     *          is owed and to whom.
     * @param _tokenId - the NFT asset queried for royalty information
     * @param royaltyBps_ - The actual royalty bps, calculated on the total sale amount
     * @param recipientsBps_ - array containing the bps of each recipient. This bps is calculated on the royalty amount and the sum of this array must be 10000 (100%)
     * @param royaltyRecipients_ - array of the recipients
     */
    function _setRoyalties(
        uint256 _tokenId,
        uint24 royaltyBps_,
        uint24[] calldata recipientsBps_,
        address[] calldata royaltyRecipients_
    ) internal {
        require(royaltyBps_ <= TOTAL_SHARES);
        uint256 i = recipientsBps_.length;
        require(i == royaltyRecipients_.length);

        uint24 sum;

        do {
            unchecked {
                --i;
                sum += recipientsBps_[i];
            }
        } while (i > 0);

        // the sum has to be equal to 100%
        require(sum == TOTAL_SHARES);

        _royaltyInfoArray[_tokenId].recipients = royaltyRecipients_;
        _royaltyInfoArray[_tokenId].bps = recipientsBps_;
        _royaltyInfoArray[_tokenId].royaltyBps = royaltyBps_;
    }

    function _resetTokenRoyalty(uint256 _tokenId) internal {
        delete _royaltyInfoArray[_tokenId];
    }
}