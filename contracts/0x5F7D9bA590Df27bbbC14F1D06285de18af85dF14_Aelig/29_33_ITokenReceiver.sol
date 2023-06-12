// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./IERC721TokenReceiver.sol";
import "./IERC1155TokenReceiver.sol";

interface ITokenReceiver is
    IERC721TokenReceiver,
    IERC1155TokenReceiver
{
    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes calldata _data
    )
    external
    returns(bytes4);

    function onERC1155Received(
        address _operator,
        address _from,
        uint256 _id,
        uint256 _value,
        bytes calldata _data
    )
    external
    returns (bytes4);

    event NFTReceived(uint256 frameId, address owner, address nftAddress, uint256 nftId);
}