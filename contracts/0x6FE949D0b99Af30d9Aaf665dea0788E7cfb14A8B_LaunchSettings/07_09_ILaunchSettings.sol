// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

interface ILaunchSettings {
    function maxAuctionLength() external returns (uint256);
    function maxAuctionLengthForNFT() external returns (uint256);

    function minAuctionLength() external returns (uint256);
    function minAuctionLengthForNFT() external returns (uint256);

    function maxCuratorFee() external returns (uint256);
    function maxCuratorFeeForNFT() external returns (uint256);

    function governanceFee() external returns (uint256);
    function governanceFeeForNFT() external returns (uint256);

    function minBidIncrease() external returns (uint256);
    function minBidIncreaseForNFT() external returns (uint256);

    function minVotePercentage() external returns (uint256);
    function minVotePercentageForNFT() external returns (uint256);

    function maxReserveFactor() external returns (uint256);
    function maxReserveFactorForNFT() external returns (uint256);

    function minReserveFactor() external returns (uint256);
    function minReserveFactorForNFT() external returns (uint256);

    function feeReceiver() external returns (address payable);
    function feeReceiverForNFT() external returns (address payable);

    function isERC1155(address nft) external returns(bool);
    function isERC721(address nft) external returns(bool);

    function getPlatformFee(address _index) external returns(uint256);
}