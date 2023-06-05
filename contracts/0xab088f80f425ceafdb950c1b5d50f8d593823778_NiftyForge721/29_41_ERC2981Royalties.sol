// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import './IERC2981Royalties.sol';

/// @dev This is a contract used to add ERC2981 support to ERC721 and 1155
abstract contract ERC2981Royalties is IERC2981Royalties {
    struct RoyaltyData {
        address recipient;
        uint96 amount;
    }

    // this variable is set to true, whenever "contract wide" royalties are set
    // this can not be undone and this takes precedence to any other royalties already set.
    bool private _useContractRoyalties;

    // those are the "contract wide" royalties, used for collections that all pay royalties to
    // the same recipient, with the same value
    // once set, like any other royalties, it can not be modified
    RoyaltyData private _contractRoyalties;

    mapping(uint256 => RoyaltyData) private _royalties;

    function hasPerTokenRoyalties() public view returns (bool) {
        return !_useContractRoyalties;
    }

    /// @inheritdoc	IERC2981Royalties
    function royaltyInfo(uint256 tokenId, uint256 value)
        public
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        // get base values
        (receiver, royaltyAmount) = _getTokenRoyalty(tokenId);

        // calculate due amount
        if (royaltyAmount != 0) {
            royaltyAmount = (value * royaltyAmount) / 10000;
        }
    }

    /// @dev Sets token royalties
    /// @param id the token id fir which we register the royalties
    function _removeRoyalty(uint256 id) internal {
        delete _royalties[id];
    }

    /// @dev Sets token royalties
    /// @param id the token id for which we register the royalties
    /// @param recipient recipient of the royalties
    /// @param value percentage (using 2 decimals - 10000 = 100, 0 = 0)
    function _setTokenRoyalty(
        uint256 id,
        address recipient,
        uint256 value
    ) internal {
        // you can't set per token royalties if using "contract wide" ones
        require(
            !_useContractRoyalties,
            '!ERC2981Royalties:ROYALTIES_CONTRACT_WIDE!'
        );
        require(value <= 10000, '!ERC2981Royalties:TOO_HIGH!');

        _royalties[id] = RoyaltyData(recipient, uint96(value));
    }

    /// @dev Gets token royalties
    /// @param id the token id for which we check the royalties
    function _getTokenRoyalty(uint256 id)
        internal
        view
        virtual
        returns (address, uint256)
    {
        RoyaltyData memory data;
        if (_useContractRoyalties) {
            data = _contractRoyalties;
        } else {
            data = _royalties[id];
        }

        return (data.recipient, uint256(data.amount));
    }

    /// @dev set contract royalties;
    ///      This can only be set once, because we are of the idea that royalties
    ///      Amounts should never change after they have been set
    ///      Once default values are set, it will be used for all royalties inquiries
    /// @param recipient the default royalties recipient
    /// @param value the default royalties value
    function _setDefaultRoyalties(address recipient, uint256 value) internal {
        require(
            _useContractRoyalties == false,
            '!ERC2981Royalties:DEFAULT_ALREADY_SET!'
        );
        require(value <= 10000, '!ERC2981Royalties:TOO_HIGH!');
        _useContractRoyalties = true;
        _contractRoyalties = RoyaltyData(recipient, uint96(value));
    }

    /// @dev allows to set the default royalties recipient
    /// @param recipient the new recipient
    function _setDefaultRoyaltiesRecipient(address recipient) internal {
        _contractRoyalties.recipient = recipient;
    }

    /// @dev allows to set a tokenId royalties recipient
    /// @param tokenId the token Id
    /// @param recipient the new recipient
    function _setTokenRoyaltiesRecipient(uint256 tokenId, address recipient)
        internal
    {
        _royalties[tokenId].recipient = recipient;
    }
}