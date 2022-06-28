// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/INftPriceOracle.sol";

contract NftPriceOracle is Ownable, INftPriceOracle {
    address public BENDDAO_ORACLE;

    constructor(address _BenddaoOracle) {
        BENDDAO_ORACLE = _BenddaoOracle;
    }

    function getNftPriceByTimestamp(address _nftContract, uint256 _timestamp)
        external
        view
        override
        returns (uint256 price)
    {
        bool completed = false;
        uint256 _numOfRoundBack = 0;

        while (!completed) {
            if (_timestamp >= INFTOracle(BENDDAO_ORACLE).getPreviousTimestamp(_nftContract, _numOfRoundBack)) {
                price = INFTOracle(BENDDAO_ORACLE).getPreviousPrice(_nftContract, _numOfRoundBack);
                completed = true;
            } else {
                _numOfRoundBack += 1;
            }
        }
    }

    function getOracleIdByTimestamp(address _nftContract, uint256 _timestamp)
        external
        view
        override
        returns (uint256 oracleId)
    {
        bool completed = false;
        uint256 _numOfRoundBack = 0;
        uint256 len = INFTOracle(BENDDAO_ORACLE).getPriceFeedLength(_nftContract);

        while (!completed) {
            if (_timestamp >= INFTOracle(BENDDAO_ORACLE).getPreviousTimestamp(_nftContract, _numOfRoundBack)) {
                completed = true;
            } else {
                _numOfRoundBack = _numOfRoundBack + 1;
            }
        }
        oracleId = len - _numOfRoundBack - 1;
    }

    function getNftPriceByOracleId(
        address _nftContract,
        uint256 _oracleId,
        uint256 _roundTimestamp
    ) external view override returns (bool verified, uint256 price) {
        uint256 len = INFTOracle(BENDDAO_ORACLE).getPriceFeedLength(_nftContract);
        uint256 _numOfRoundBack = len - _oracleId - 1;
        uint256 oracleTimestamp;
        uint256 oracleTimestampNext;

        oracleTimestamp = INFTOracle(BENDDAO_ORACLE).getPreviousTimestamp(_nftContract, _numOfRoundBack);

        if (_numOfRoundBack == 0) {
            verified = _roundTimestamp >= oracleTimestamp;
        } else {
            oracleTimestampNext = INFTOracle(BENDDAO_ORACLE).getPreviousTimestamp(_nftContract, _numOfRoundBack - 1);
            verified = _roundTimestamp >= oracleTimestamp && _roundTimestamp < oracleTimestampNext;
        }

        if (verified) {
            price = INFTOracle(BENDDAO_ORACLE).getPreviousPrice(_nftContract, _numOfRoundBack);
        }
    }
}