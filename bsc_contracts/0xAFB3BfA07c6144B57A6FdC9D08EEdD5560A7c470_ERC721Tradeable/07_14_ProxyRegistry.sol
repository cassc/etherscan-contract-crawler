//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;
import "@openzeppelin/contracts/access/Ownable.sol";

contract ProxyRegistry is Ownable {
    mapping(address => bool) public proxies;

    function setProxy(address proxyAddress, bool value) external onlyOwner {
        proxies[proxyAddress] = value;
    }
}