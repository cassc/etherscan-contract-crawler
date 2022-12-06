// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../../../contracts/mixins/nftMarket/NFTMarketExhibition.sol";

contract $NFTMarketExhibition is NFTMarketExhibition {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    event $_getExhibitionForPayment_Returned(address payable arg0, uint16 arg1);

    constructor() {}

    function $_addNftToExhibition(address nftContract,uint256 tokenId,uint256 exhibitionId) external {
        return super._addNftToExhibition(nftContract,tokenId,exhibitionId);
    }

    function $_getExhibitionForPayment(address nftContract,uint256 tokenId) external returns (address payable, uint16) {
        (address payable ret0, uint16 ret1) = super._getExhibitionForPayment(nftContract,tokenId);
        emit $_getExhibitionForPayment_Returned(ret0, ret1);
        return (ret0, ret1);
    }

    function $_removeNftFromExhibition(address nftContract,uint256 tokenId) external {
        return super._removeNftFromExhibition(nftContract,tokenId);
    }

    receive() external payable {}
}