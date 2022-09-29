pragma solidity ^0.8.17;
/// @dev price
struct Price {
    uint256 nom; // numerator
    uint256 denom; // denominator
}

interface ISaleAlgorithm {
    function setAlgorithm(uint256 positionId) external;

    function setPrice(uint256 positionId, Price calldata price) external;
}