// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

interface ISBTC {
    struct TxData {
        bytes32 hash;
        address creator;
        address seller;
        address token;
        uint256 fee;
        uint256 timestamp;
    }

    struct Collection {
        address collection;
        uint256 nftId;
    }

    function paymentTokenByIndex(uint256 sbtId_, uint256 index_) external view returns (address);

    function paymentTokensCount(uint256 sbtId_) external view returns (uint256);

    function sbtId(
        address seller_,
        address collection_,
        uint256 id_
    ) external view returns (uint256);

    function txsData(
        uint256 sbtId_,
        uint256 offset_,
        uint256 limit_
    ) external view returns (TxData[] memory txs_);

    function unpaidTotalFee(uint256 sbtId_, address collection_) external view returns (uint256);

    function setUnpaidFee(
        string[] memory tokenURI_,
        address[] memory collections_,
        uint256[] memory ids_,
        TxData[] memory txs_
    ) external;

    function closeUnpaidFee(uint256[] memory sbtIds) external payable;
}