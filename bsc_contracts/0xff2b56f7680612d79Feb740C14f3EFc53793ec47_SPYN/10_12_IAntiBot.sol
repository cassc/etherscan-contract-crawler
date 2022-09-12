pragma solidity >=0.5.0;

interface IAntiBot {
    function onPreTransferCheck(
        address from,
        address to
    ) external view returns (bool);
}