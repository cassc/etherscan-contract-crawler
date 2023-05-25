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
 * @title ERC2981PersonalEditions                            *
 *                                                           *
 * @notice Adds ERC2981 support to {ERC1155}                 *
 *                                                           *
 * @dev {ERC2981} royalties for self-sovreign collections    *
 *                                                           *
 * @custom:security-contact [email protected]                    *
 ************************************************************/

contract ERC2981PersonalEditions {
    uint24 private constant TOTAL_SHARES = 10000; // 10,000 = 100% (total sale price)
    uint24 internal _royaltyBps;
    /// @notice the royaltyRecipient or contract deployer.
    address payable internal _royaltyRecipient;

    /**
     * @notice Called with the sale price to determine how much royalty
     *          is owed and to whom.
     * @param _salePrice - the sale price of the NFT asset specified by _tokenId
     * @return recipient - address of who should be sent the royalty payment
     * @return royaltyAmount - the royalty payment amount for _salePrice
     */
    function royaltyInfo(
        uint256,
        uint256 _salePrice
    ) external view returns (address, uint256) {
        return (_royaltyRecipient, (_salePrice * _royaltyBps) / TOTAL_SHARES);
    }
}