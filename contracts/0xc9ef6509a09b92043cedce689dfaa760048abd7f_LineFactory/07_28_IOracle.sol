pragma solidity 0.8.16;

interface IOracle {
    /** current price for token asset. denominated in USD */
    function getLatestAnswer(address token) external returns (int);

    /** Readonly function providing the current price for token asset. denominated in USD */
    function _getLatestAnswer(address token) external view returns (int);
}