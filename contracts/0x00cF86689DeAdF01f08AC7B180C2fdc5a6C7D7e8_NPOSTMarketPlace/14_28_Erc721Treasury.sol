// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

import "../../libs/utils/ERC721OnlySelfInitHolder.sol";

abstract contract Erc721Treasury is
    ERC721OnlySelfInitHolder
{

////////////////////////////////////////// fields definition

    /** see https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps */
    uint256[50] private __gap;

////////////////////////////////////////// method like deposit

    function _takeErc721FromTokenOwner(
        address _tokenAddress,
        uint256 _tokenId
    )
        internal
    {
        IERC721Upgradeable token = IERC721Upgradeable(_tokenAddress);
        require(token.ownerOf(_tokenId) == msg.sender, '_takeErc721FromTokenOwner: only self owned tokens allowed');
        token.safeTransferFrom(msg.sender, address(this), _tokenId);
    }

    function _sendErc721ToAccount(
        address _account,
        address _tokenAddress,
        uint256 _tokenId
    )
        internal
    {
        IERC721Upgradeable(_tokenAddress).safeTransferFrom(address(this), _account, _tokenId);
    }

}