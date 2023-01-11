pragma solidity >=0.5;

interface ISolidlyBaseV1Pair {
    function getReserves()
        external
        view
        returns (
            uint112 _reserve0,
            uint112 _reserve1,
            uint32 _blockTimestampLast
        );

    function reserve0CumulativeLast() external view returns (uint256);

    function reserve1CumulativeLast() external view returns (uint256);

    function currentCumulativePrices()
        external
        view
        returns (
            uint256 reserve0Cumulative,
            uint256 reserve1Cumulative,
            uint256 blockTimestamp
        );

    function stable() external view returns (bool);

    function observationLength() external view returns (uint256);

    function observations(uint256) external view returns (uint256 timestamp, uint256 reserve0Cumulative, uint256 reserve1Cumulative);
}