// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../../../contracts/mixins/nftMarket/NFTMarketReserveAuction.sol";

abstract contract $NFTMarketReserveAuction is NFTMarketReserveAuction {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    event $_getNextAndIncrementAuctionId_Returned(uint256 arg0);

    event $_getExhibitionForPayment_Returned(address payable arg0, uint16 arg1);

    event $_distributeFunds_Returned(uint256 arg0, uint256 arg1, uint256 arg2);

    constructor(address payable _treasury, address _feth, uint16 protocolFeeInBasisPoints, address _royaltyRegistry, bool _assumePrimarySale, uint256 duration) FoundationTreasuryNode(_treasury) FETHNode(_feth) MarketFees(protocolFeeInBasisPoints, _royaltyRegistry, _assumePrimarySale) NFTMarketReserveAuction(duration) {}

    function $feth() external view returns (IFethMarket) {
        return feth;
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

    function $_getSellerOf(address nftContract,uint256 tokenId) external view returns (address payable) {
        return super._getSellerOf(nftContract,tokenId);
    }

    function $_isInActiveAuction(address nftContract,uint256 tokenId) external view returns (bool) {
        return super._isInActiveAuction(nftContract,tokenId);
    }

    function $_initializeNFTMarketAuction() external {
        return super._initializeNFTMarketAuction();
    }

    function $_getNextAndIncrementAuctionId() external returns (uint256) {
        (uint256 ret0) = super._getNextAndIncrementAuctionId();
        emit $_getNextAndIncrementAuctionId_Returned(ret0);
        return (ret0);
    }

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

    function $_distributeFunds(address nftContract,uint256 tokenId,address payable seller,uint256 price,address payable buyReferrer,address payable sellerReferrerPaymentAddress,uint16 sellerReferrerTakeRateInBasisPoints) external returns (uint256, uint256, uint256) {
        (uint256 ret0, uint256 ret1, uint256 ret2) = super._distributeFunds(nftContract,tokenId,seller,price,buyReferrer,sellerReferrerPaymentAddress,sellerReferrerTakeRateInBasisPoints);
        emit $_distributeFunds_Returned(ret0, ret1, ret2);
        return (ret0, ret1, ret2);
    }

    function $_sendValueWithFallbackWithdraw(address payable user,uint256 amount,uint256 gasLimit) external {
        return super._sendValueWithFallbackWithdraw(user,amount,gasLimit);
    }

    function $__ReentrancyGuard_init() external {
        return super.__ReentrancyGuard_init();
    }

    function $__ReentrancyGuard_init_unchained() external {
        return super.__ReentrancyGuard_init_unchained();
    }

    function $_beforeAuctionStarted(address arg0,uint256 arg1) external {
        return super._beforeAuctionStarted(arg0,arg1);
    }

    function $_getMinIncrement(uint256 currentAmount) external pure returns (uint256) {
        return super._getMinIncrement(currentAmount);
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