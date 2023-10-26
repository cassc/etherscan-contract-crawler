// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import './ERC2981Base.sol';
import './OwnableUpgradeable.sol';

/// @dev This is a contract used to add ERC2981 support to ERC721 and 1155
/// @dev This implementation has the same royalties for each and every tokens
abstract contract ERC2981Royalties is ERC2981Base {
    RoyaltyInfo private _contractRoyalties;
    mapping(uint256 => RoyaltyInfo) private _individualRoyalties;

    
    /// @dev Sets token royalties
    /// @param tokenId the token id fir which we register the royalties
    /// @param recipient recipient of the royalties
    /// @param value percentage (using 2 decimals - 10000 = 100, 0 = 0)
    function setTokenRoyalty(uint256 tokenId, address recipient, uint256 value) public override {
        require(msg.sender == OwnableUpgradeable(address(this)).owner(), "Not Owner");
        require(value <= 10000, 'ERC2981Royalties: Too high');
        if (tokenId == 0) {
            _contractRoyalties = RoyaltyInfo(recipient, uint24(value));
        } else {
            _individualRoyalties[tokenId] = RoyaltyInfo(recipient, uint24(value));
        }
    }

    function royaltyInfo(uint256 tokenId, uint256 value) public view override returns (address receiver, uint256 royaltyAmount) {
        RoyaltyInfo memory royalties = _individualRoyalties[tokenId].recipient != address(0)? _individualRoyalties[tokenId]: _contractRoyalties;
        
        receiver = royalties.recipient;
        royaltyAmount = (value * royalties.amount) / 10000;
    }
}