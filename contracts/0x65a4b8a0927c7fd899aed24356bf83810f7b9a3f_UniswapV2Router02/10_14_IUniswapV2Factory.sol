// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function migrator() external view returns (address);
    function isOperator() external view returns (bool);
    function wethAddress() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
    function setMigrator(address) external;

    function pairCodeHash() external view returns (bytes32);

    function pairFor(address tokenA, address tokenB) external view returns (address pair);

    function isStarkExContractFrozen() external view returns (bool);

    function starkExContract() external view returns (address);

    // Event emmiters

  function withdrawalRequested(address token0, address token1, address user, uint amount, uint withdrawalId) external;
  function withdrawalCompleted(address token0, address token1, address user, uint amount, uint token0Amount, uint token1Amount) external;
  function withdrawalForced(address token0, address token1, address user) external;
}