pragma solidity ^0.8.0;

interface IWhitelist {
    function isWhitelisted(address clientAddress) external view returns (bool);
}