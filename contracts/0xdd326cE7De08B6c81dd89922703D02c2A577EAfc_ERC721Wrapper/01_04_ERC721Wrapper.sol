// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../interfaces/INftWrapper.sol";

contract ERC721Wrapper is INftWrapper {
    function transferNFT(
        address _sender,
        address _recipient,
        address _nftContract,
        uint256 _nftId
    ) external override returns (bool) {
        IERC721(_nftContract).safeTransferFrom(_sender, _recipient, _nftId);
        return true;
    }

    function isOwner(
        address _owner,
        address _nftContract,
        uint256 _tokenId
    ) external view override returns (bool) {
        return IERC721(_nftContract).ownerOf(_tokenId) == _owner;
    }

    function wrapAirdropAcceptor(
        address _recipient,
        address _nftContract,
        uint256 _nftId,
        address _beneficiary
    ) external override returns (bool) {
        IERC721(_nftContract).safeTransferFrom(address(this), _recipient, _nftId, abi.encode(_beneficiary));

        return true;
    }
}