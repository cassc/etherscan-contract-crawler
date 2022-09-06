// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//import '@openzeppelin/contracts/utils/introspection/ERC165.sol';
import './IERC2981Royalties.sol';

/// @dev This is a contract used to add ERC2981 support to ERC721 and 1155
/// @dev This implementation has the same royalties for each and every tokens
abstract contract ERC2981ContractWideRoyalties is IERC2981Royalties {

    struct RoyaltyInfo {
        address recipient;
        uint24 amount;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        returns (bool)
    {
        return
            interfaceId == type(IERC2981Royalties).interfaceId;
    }

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