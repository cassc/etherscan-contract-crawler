pragma solidity ^0.8.0;

interface IFuturesGateway {
    function withdraw(
        address manager,
        address trader,
        uint256 amount
    ) external;
}