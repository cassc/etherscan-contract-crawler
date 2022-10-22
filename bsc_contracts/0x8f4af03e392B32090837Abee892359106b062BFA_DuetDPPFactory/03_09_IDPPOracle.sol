pragma solidity 0.8.9;
pragma experimental ABIEncoderV2;

interface IDPPOracle {
    function init(
        address owner,
        address maintainer,
        address baseTokenAddress,
        address quoteTokenAddress,
        uint256 lpFeeRate,
        address mtFeeRateModel,
        uint256 k,
        uint256 i,
        address o,
        bool isOpenTWAP,
        bool isOracleEnabled
    ) external;

    function _MT_FEE_RATE_MODEL_() external returns (address);

    function _O_() external returns (address);

    function _IS_ORACLE_ENABLED() external returns (bool);
}