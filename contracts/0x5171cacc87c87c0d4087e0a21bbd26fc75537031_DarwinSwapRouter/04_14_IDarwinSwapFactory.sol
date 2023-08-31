pragma solidity ^0.8.14;

import "./IDarwinLiquidityBundles.sol";
import "./IMasterChef.sol";

interface IDarwinSwapFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function dev() external view returns (address);
    function lister() external view returns (address);
    function feeTo() external view returns (address);
    function router() external view returns (address);
    function liquidityBundles() external view returns (IDarwinLiquidityBundles);
    function masterChef() external view returns (IDarwinMasterChef);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function INIT_CODE_HASH() external pure returns(bytes32);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setDev(address) external;
    function setLister(address) external;
    function setRouter(address) external;
}