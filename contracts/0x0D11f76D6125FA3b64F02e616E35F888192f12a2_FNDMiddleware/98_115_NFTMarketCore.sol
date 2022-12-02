// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../../../contracts/mixins/nftMarket/NFTMarketCore.sol";

abstract contract $NFTMarketCore is NFTMarketCore {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor(address _feth) FETHNode(_feth) {}

    function $feth() external view returns (IFethMarket) {
        return feth;
    }

    function $_beforeAuctionStarted(address arg0,uint256 arg1) external {
        return super._beforeAuctionStarted(arg0,arg1);
    }

    function $_transferFromEscrow(address nftContract,uint256 tokenId,address recipient,address authorizeSeller) external {
        return super._transferFromEscrow(nftContract,tokenId,recipient,authorizeSeller);
    }

    function $_transferFromEscrowIfAvailable(address nftContract,uint256 tokenId,address recipient) external {
        return super._transferFromEscrowIfAvailable(nftContract,tokenId,recipient);
    }

    function $_transferToEscrow(address nftContract,uint256 tokenId) external {
        return super._transferToEscrow(nftContract,tokenId);
    }

    function $_getMinIncrement(uint256 currentAmount) external pure returns (uint256) {
        return super._getMinIncrement(currentAmount);
    }

    function $_getSellerOf(address nftContract,uint256 tokenId) external view returns (address payable) {
        return super._getSellerOf(nftContract,tokenId);
    }

    function $_getSellerOrOwnerOf(address nftContract,uint256 tokenId) external view returns (address payable) {
        return super._getSellerOrOwnerOf(nftContract,tokenId);
    }

    function $_tryUseFETHBalance(uint256 totalAmount,bool shouldRefundSurplus) external {
        return super._tryUseFETHBalance(totalAmount,shouldRefundSurplus);
    }

    function $_disableInitializers() external {
        return super._disableInitializers();
    }

    function $_getInitializedVersion() external view returns (uint8) {
        return super._getInitializedVersion();
    }

    function $_isInitializing() external view returns (bool) {
        return super._isInitializing();
    }
}