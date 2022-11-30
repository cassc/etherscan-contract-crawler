// SPDX-License-Identifier: Apache-2.0



pragma solidity ^0.8.0;

import "./token/ERC721/IERC721.sol";

interface IEAGLENFT is IERC721 {
    // @initEagleToken This function can only be used once
    // The purpose is to load EagleToken address
    function initEagleToken(address _EagleToken) external;

    // @setNFTConfigReceiveOnlyEAGLETOKEN Set NFTConfig Receive Only EAGLETOKEN
    // Receive the reward of the specified month
    // Only after receiving rewards can they be sold in the market
    function setNFTConfigReceiveOnlyEAGLETOKEN(uint256 _tokenId, uint256 _batch)
        external;

    // @getNFTCreateTime Query appoint NFT create time
    function getNFTCreateTime(uint256 tokenId) external view returns (uint256);

    // @getNFTDraw Query Whether the reward has been received in the specified month
    function getNFTDraw(uint256 tokenId, uint256 _batch)
        external
        view
        returns (bool);

    // @tokenType Query the type of an NFT
    function tokenType(uint256 tokenId) external view returns (string memory);

    // @getNFTEAGLESerial get nft type
    function getNFTEAGLESerial(uint256 tokenId) external view returns (uint256);

    // @getNFTCardNumber Query the respective quantity of the current two NFTs
    function getNFTCardNumber()
        external
        pure
        returns (uint128 tigerEaglecardNum, uint128 PhoenixEagleCardNum);

    // @tokenDescribe Query the Describe of an NFT
    function tokenDescribe(uint256 tokenId)
        external
        view
        returns (string memory);

    function getNFTConfig()external view returns (address[] memory, uint[] memory);
}