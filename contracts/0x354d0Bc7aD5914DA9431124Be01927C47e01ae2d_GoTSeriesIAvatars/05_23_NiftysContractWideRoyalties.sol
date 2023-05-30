// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './ERC2981Base.sol';
import '@openzeppelin/contracts/utils/introspection/ERC165.sol';

/// @dev This is a contract used to add ERC2981 support to ERC721, 721A, 1155
/// @dev This implementation has the same royalties for each and every tokens
abstract contract NiftysContractWideRoyalties is ERC2981Base {
    uint256 public constant ROYALTY_FEE_DENOMINATOR = 100_000;

    RoyaltyInfo private _royalties;

    /// @dev Sets token royalties
    /// @param recipient recipient of the royalties
    /// @param value percentage (10000 = 10%, 0 = 0)
    function _setRoyalties(address recipient, uint24 value) internal {
        require(value <= ROYALTY_FEE_DENOMINATOR, 'ERC2981Royalties: Too high');
        _royalties = RoyaltyInfo(recipient, uint24(value));
        emit RoyaltyFeeChanged(recipient, value);
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
        royaltyAmount = (value * royalties.amount) / ROYALTY_FEE_DENOMINATOR;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC2981Base)
        returns (bool)
    {
        return interfaceId == type(ERC2981Base).interfaceId || super.supportsInterface(interfaceId);
    }

    function royaltyWallet() public view returns (address) {
        return _royalties.recipient;
    }

    function royaltyFee() public view returns (uint24) {
        return _royalties.amount;
    }

    event RoyaltyFeeChanged(address recipient, uint24 royalty);
}