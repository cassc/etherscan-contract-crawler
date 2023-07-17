// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

interface IViralswapFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function migrator() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function getVault(address tokenA, address tokenB) external view returns (address vault);
    function allVaults(uint) external view returns (address vault);
    function allVaultsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);
    function createVault(uint tokenOutPerTokenIn, address tokenIn, address tokenOut, address router, uint feeOnTokenOutTransferBIPS) external returns (address vault);

    function addQuota(address tokenA, address tokenB, uint quota) external;
    function updateRouterInVault(address tokenA, address tokenB, address _viralswapRouter02) external;
    function withdrawERC20FromVault(address tokenA, address tokenB, address tokenToWithdraw, address to) external;

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
    function setMigrator(address) external;

    function pairCodeHash() external pure returns (bytes32);
    function vaultCodeHash() external pure returns (bytes32);

    function computeProfitMaximizingTrade(
        uint256 truePriceTokenA,
        uint256 truePriceTokenB,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (bool, uint256);
}