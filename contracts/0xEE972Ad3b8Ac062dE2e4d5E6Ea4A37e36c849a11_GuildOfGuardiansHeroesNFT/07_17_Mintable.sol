pragma solidity ^0.8.0;

interface Mintable {
    function mintFor(
        address to,
        uint256 amount,
        bytes memory mintingBlob
    ) external;
}