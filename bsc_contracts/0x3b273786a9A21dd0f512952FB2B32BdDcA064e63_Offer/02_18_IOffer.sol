// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//@dev Only use for nft because it has offer functions
interface IOffer {
    function makeOffer(
        address _contractERC721,
        uint256 _tokenId,
        address _contractERC20,
        uint _price
    ) external payable;
    function acceptOffer(
        address _contractERC721,
        uint256 _tokenId,
        uint256 _offerId
    ) external;
    function cancelOffer(
        address _contractERC721,
        uint256 _tokenId,
        uint256 _offerId
    ) external;
}