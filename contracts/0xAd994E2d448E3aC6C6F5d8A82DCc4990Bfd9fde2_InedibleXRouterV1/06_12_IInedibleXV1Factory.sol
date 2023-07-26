// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.0;

interface IInedibleXV1Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint pairLength
    );

    event InedibleCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint pairLength,
        bool launch,
        uint lock
    );

    function treasury() external view returns (address);

    function feeTo() external view returns (address);

    function dao() external view returns (address);

    function getPair(
        address tokenA,
        address tokenB
    ) external view returns (address pair);

    function allPairs(uint) external view returns (address pair);

    function allPairsLength() external view returns (uint);

    function createPair(
        address tokenA,
        address tokenB,
        bool launch,
        uint16 launchFeePct,
        uint40 lock
    ) external returns (address pair);

    function setFeeTo(address) external;

    // added by inedible
    function setLaunchFeePct(uint16 _launchFeePct) external;

    function setMinSupplyPct(uint16 _minSupplyPct) external;

    function transferOwnership(address _newDao) external;

    function renounceOwnership() external;

    function acceptOwnership() external;
}