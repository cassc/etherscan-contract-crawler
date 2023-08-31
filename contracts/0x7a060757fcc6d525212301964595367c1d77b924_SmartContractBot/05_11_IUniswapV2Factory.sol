// SPDX-License-Identifier: No License

/* 
SmartContractBot is an automated utility designed to optimize the process of developing, deploying, and maintaining smart contracts on the blockchain. With features like automatic audits, optimization tips, real-time monitoring, and more, it becomes an indispensable tool for developers and enterprises alike.

Website - https://roiubinyhdlogin.gitbook.io/smartcontractbot/
Telegram - https://t.me/SmartContractBotEth
Twitter - https://twitter.com/ContractBotEth
*/


pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}