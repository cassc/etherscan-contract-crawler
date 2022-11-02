// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IProxyRegistry {
	function proxies(address owner_) external view returns (address);
}

contract ProxyRegistry {
    // owner => operator
	mapping (address => address) public proxies;
	
	constructor() {}    
}