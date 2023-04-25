pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IAssetReader is IERC20 {
    function pool() external view returns (address);
    function underlyingToken() external view returns (address);
    function underlyingTokenDecimals() external view returns (uint8);
    function cash() external view returns (uint256);
    function liability() external view returns (uint256);
}