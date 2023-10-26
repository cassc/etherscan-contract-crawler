// SPDX-License-Identifier: MIT

/// @title ERC721 URI Storage Extension

/// This contract and the contracts it imports are copied from our good friend dievardump, with deep thanks and love.
/// https://github.com/dievardump/EIP2981-implementation/blob/9d7da405f16adfddb2b9a528d146e1049fcf5e5d/contracts/ERC2981ContractWideRoyalties.sol
///
/// We have modified the pragma and the way imports are specified.

pragma solidity 0.8.7;

import '@openzeppelin/contracts/utils/introspection/ERC165.sol';

import { ERC2981Royalties, IERC2981Royalties } from './ERC2981Royalties.sol';

/// @dev This is a contract used to add ERC2981 support to ERC721 contracts
/// @dev This implementation has the same royalties for each and every token
abstract contract ERC2981ContractWideRoyalties is ERC2981Royalties {
    RoyaltyInfo private _royalties;

    /// @dev Sets token royalties
    /// @param recipient recipient of the royalties
    /// @param value percentage (using 2 decimals - 10000 = 100, 0 = 0)
    function _setRoyalties(address recipient, uint256 value) internal {
        require(value <= 10000, 'ERC2981Royalties: Too high');
        _royalties = RoyaltyInfo(recipient, uint24(value));
    }

    /// @inheritdoc	IERC2981Royalties
    function royaltyInfo(uint256, uint256 value)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        RoyaltyInfo memory royalties = _royalties;
        receiver = royalties.recipient;
        royaltyAmount = (value * royalties.amount) / 10000;
    }
}