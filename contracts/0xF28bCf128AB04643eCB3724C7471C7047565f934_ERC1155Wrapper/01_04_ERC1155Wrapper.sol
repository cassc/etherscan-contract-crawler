// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "../interfaces/INftWrapper.sol";

contract ERC1155Wrapper is INftWrapper {
    function transferNFT(
        address _sender,
        address _recipient,
        address _nftContract,
        uint256 _nftId
    ) external override returns (bool) {
        IERC1155(_nftContract).safeTransferFrom(_sender, _recipient, _nftId, 1, "");
        return true;
    }

    function isOwner(
        address _owner,
        address _nftContract,
        uint256 _tokenId
    ) external view override returns (bool) {
        return IERC1155(_nftContract).balanceOf(_owner, _tokenId) > 0;
    }

    function wrapAirdropAcceptor(
        address _recipient,
        address _nftContract,
        uint256 _nftId,
        address _beneficiary
    ) external override returns (bool) {
        IERC1155(_nftContract).safeTransferFrom(address(this), _recipient, _nftId, 1, abi.encode(_beneficiary));

        return true;
    }
}