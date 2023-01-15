pragma solidity >=0.5.0;

interface IProDexV2Callee {
    function proDexV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external;
}