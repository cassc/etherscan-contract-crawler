// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface INftPriceOracle {
    function getNftPriceByTimestamp(address _nftContract, uint256 _timestamp) external view returns (uint256 price);

    function getNftPriceByOracleId(
        address _nftContract,
        uint256 _oracleId,
        uint256 _roundTimestamp
    ) external view returns (bool verified, uint256 price);

    function getOracleIdByTimestamp(address _nftContract, uint256 _timestamp) external view returns (uint256 oracleId);
}

/************
@title INFTOracle interface
@notice Interface for NFT price oracle.*/
interface INFTOracle {
    /* CAUTION: Price uint is ETH based (WEI, 18 decimals) */
    // get asset price
    function getAssetPrice(address _nftContract) external view returns (uint256);

    // get latest timestamp
    function getLatestTimestamp(address _nftContract) external view returns (uint256);

    // get previous price with _back rounds
    function getPreviousPrice(address _nftContract, uint256 _numOfRoundBack) external view returns (uint256);

    // get previous timestamp with _back rounds
    function getPreviousTimestamp(address _nftContract, uint256 _numOfRoundBack) external view returns (uint256);

    function setAssetData(address _nftContract, uint256 _price) external;

    function setPause(address _nftContract, bool val) external;

    function setTwapInterval(uint256 _twapInterval) external;

    function getPriceFeedLength(address _nftContract) external view returns (uint256 length);
}