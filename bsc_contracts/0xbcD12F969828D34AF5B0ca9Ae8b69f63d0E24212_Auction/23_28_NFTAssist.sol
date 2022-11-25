//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title NFTAssist
 * @author gotbit
 */

import '@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol';
import '@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol';
import '@openzeppelin/contracts/utils/introspection/ERC165Checker.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/token/ERC1155/IERC1155.sol';
import '@openzeppelin/contracts/token/ERC1155/ERC1155.sol';
import './interfaces/INFTAssist.sol';

contract NFTAssist is INFTAssist, ERC1155Holder, ERC721Holder {
    using ERC165Checker for address;

    /// @dev Allows to show nft type of selected address
    /// @param token_ address of token to be interface checked
    /// @return interface type of nft
    function _getNFTType(address token_) internal view returns (NFTType) {
        if (token_.supportsInterface(type(IERC721).interfaceId)) return NFTType.ERC721;
        if (token_.supportsInterface(type(IERC1155).interfaceId)) return NFTType.ERC1155;
        else revert WrongNFTType();
    }

    /// @dev Transfers nft to selected address with interface type of nft
    /// @param from address who sends nft to new owner
    /// @param to address to receive nft
    /// @param nft address of nft to be bougth
    /// @param tokenId id of nft token to be bougth
    function _transferNFT(
        address from,
        address to,
        address nft,
        uint256 tokenId,
        uint256 amount
    ) internal {
        NFTType nftType = _getNFTType(nft);
        if (nftType == NFTType.ERC721) IERC721(nft).transferFrom(from, to, tokenId);
        if (nftType == NFTType.ERC1155)
            IERC1155(nft).safeTransferFrom(from, to, tokenId, amount, '');
    }

    function _isERC1155(address nft) internal view returns (bool) {
        NFTType nftType = _getNFTType(nft);
        if (nftType == NFTType.ERC1155) return true;
        return false;
    }

    function _tokenURI(address nft, uint256 tokenId)
        internal
        view
        returns (string memory)
    {
        NFTType nftType = _getNFTType(nft);
        if (nftType == NFTType.ERC721) return ERC721(nft).tokenURI(tokenId);
        if (nftType == NFTType.ERC1155) return ERC1155(nft).uri(tokenId);
        return '';
    }

    /// @dev Prevents actions with nft by not the owner
    /// @param nft address of owner nft
    /// @param tokenId owner's nft token id
    function _checkOwnership(
        address nft,
        uint256 tokenId,
        address user
    ) internal view {
        NFTType nftType = _getNFTType(nft);
        if (nftType == NFTType.ERC721)
            if (IERC721(nft).ownerOf(tokenId) != user) revert CallerIsNotNFTOwner();
        if (nftType == NFTType.ERC1155)
            if (IERC1155(nft).balanceOf(user, tokenId) == 0) revert CallerIsNotNFTOwner();
    }

    function _getNFT(address nft, uint256 tokenId) internal view returns (NFT memory) {
        return
            NFT({
                nftContract: nft,
                tokenId: tokenId,
                tokenURI: _tokenURI(nft, tokenId),
                nftType: _getNFTType(nft)
            });
    }
}