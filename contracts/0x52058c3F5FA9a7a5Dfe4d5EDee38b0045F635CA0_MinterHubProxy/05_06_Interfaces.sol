pragma solidity ^0.8.1;

interface Hub {
    function transferToChain(
        address _tokenContract,
        bytes32 _destinationChain,
        bytes32 _destination,
        uint256 _amount,
        uint256 _fee
    ) external;
}