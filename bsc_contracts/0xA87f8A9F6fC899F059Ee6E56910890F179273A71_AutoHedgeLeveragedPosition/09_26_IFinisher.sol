pragma solidity 0.8.6;

interface IFinisher {
    function onFlw(
        uint256 amount,
        uint256 fee,
        bytes memory data
    ) external;
}