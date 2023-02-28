// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "../interfaces/ILiquidityManagerNFT.sol";

/// @title Manage the Liquidity NFT
/// @notice This NFT is voteable
contract LiquidityManagerNFT is
    ILiquidityManagerNFT,
    ERC721Upgradeable,
    ERC721EnumerableUpgradeable
{
    uint256 public override tokenID;

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721Upgradeable, ERC721EnumerableUpgradeable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    /**
     * @dev Adjusts votes when tokens are transferred.
     *
     * Emits a {Votes-DelegateVotesChanged} event.
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal virtual override {
        super._afterTokenTransfer(from, to, tokenId, batchSize);
    }

    /**
     * @dev Gets the list of token IDs of the requested owner.
     * @param owner address owning the tokens
     * @return uint256[] List of token IDs owned by the requested address
     */
    function tokensOfOwner(address owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 balance = balanceOf(owner);
        uint256[] memory tokens = new uint256[](balance);

        for (uint256 i = 0; i < balance; i++) {
            tokens[i] = tokenOfOwnerByIndex(owner, i);
        }

        return tokens;
    }

    function _burnNFT(uint256 tokenId) internal {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "!Burn"
        );
        _burn(tokenId);
    }
}