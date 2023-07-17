// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

//@title IRoyaltyInfo is used for communicating with Davinci contracts for getting royalty info.
//@dev see{ERC721, ERC1155}
interface IRoyaltyInfo {
    //@notice function used for getting royalty info. for the given tokenId and calculates the royalty Fee for the given sale price.
    //@param _tokenId unique id of NFT.
    //@param price sale price of the NFT.
    //@returns royalty receivers,royalty value ,it can be calculated from the royaltyFee permiles.
    //dev see {ERC2981}
    function royaltyInfo(
        uint256 _tokenId,
        uint256 price)
        external
        view
        returns(uint96[] memory, address[] memory, uint256);
}