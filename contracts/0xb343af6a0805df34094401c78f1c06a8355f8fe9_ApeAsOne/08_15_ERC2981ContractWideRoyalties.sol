// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./ERC2981Base.sol";

/// @dev This is a contract used to add ERC2981 support to ERC721 and 1155
/// @dev This implementation has the same royalties for each and every tokens
abstract contract ERC2981ContractWideRoyalties is ERC2981Base {
    RoyaltyInfo internal _royalties;

    /// @inheritdoc	IERC2981Royalties
    function royaltyInfo(uint256, uint256 _value)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        receiver = _royalties.receiver;
        royaltyAmount = (_value * _royalties.amount) / 10000;
    }

    /// @dev Sets royalties amount
    /// @param _value percentage (using 2 decimals - 10000 = 100, 0 = 0)
    function _setRoyaltiesAmount(uint256 _value) internal {
        require(_value <= 10000, "ERC2981Royalties: Too high");
        _royalties.amount = _value;
    }

    /// @dev Sets royalties receiver
    /// @param _receiver receiver of the royalties
    function _setRoyaltiesReceiver(address _receiver) internal {
        _royalties.receiver = _receiver;
    }
}