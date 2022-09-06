pragma solidity 0.6.12;

interface IGetAuctionInfo {
    function onAuction(address uToken, uint nftIndexForUToken) external view returns (bool);
}