pragma solidity 0.8.6;

interface IPancakeFactory {
    function getPair(address _tokenA, address _tokenB) external view returns(address);
}