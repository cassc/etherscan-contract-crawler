// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

interface IXNFT {

    function pledge(address collection, uint256 tokenId, uint256 nftType) external;
    function pledge721(address _collection, uint256 _tokenId) external;
    function pledge1155(address _collection, uint256 _tokenId) external;
    function getOrderDetail(uint256 orderId) external view returns(address collection, uint256 tokenId, address pledger);
    function isOrderLiquidated(uint256 orderId) external view returns(bool);
    function withdrawNFT(uint256 orderId) external;


    // onlyController
    function notifyOrderLiquidated(address xToken, uint256 orderId, address liquidator, uint256 liquidatedPrice) external;
    function notifyRepayBorrow(uint256 orderId) external;

}