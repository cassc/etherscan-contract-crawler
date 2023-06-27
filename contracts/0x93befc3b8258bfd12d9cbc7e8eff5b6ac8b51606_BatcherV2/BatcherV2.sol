/**
 *Submitted for verification at Etherscan.io on 2023-06-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

struct TransactionData {
	address target;
	bytes data;
	uint256 value;
}

contract BatcherV2 {
	// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-1167.md
    address private immutable original;
    bytes32 private byteCode;
	uint n;
	address private immutable deployer;
	
	constructor(uint _n) {
        original = address(this);
		deployer = msg.sender;
		createProxies(_n);
	}

	function createProxies(uint _n) internal {
		bytes memory miniProxy = bytes.concat(bytes20(0x3D602d80600A3D3981F3363d3d373d3D3D363d73), bytes20(address(this)), bytes15(0x5af43d82803e903d91602b57fd5bf3));
        byteCode = keccak256(abi.encodePacked(miniProxy));  
		address proxy;
		uint oldN = n;
		for(uint i=0; i<_n; i++) {
	        bytes32 salt = keccak256(abi.encodePacked(msg.sender, i+oldN));
			assembly {
	            proxy := create2(0, add(miniProxy, 32), mload(miniProxy), salt)
			}
			require(proxy != address(0), "Failed to deploy contract.");
		}
		// update n
		n = oldN + _n;
	} 

	function callback(TransactionData calldata txData) external {
		require(msg.sender == original, "Only original can call this function.");
		(bool success, ) = txData.target.call{value: txData.value}(txData.data);
	}

    function proxyFor(address sender, uint i) public view returns (address proxy) {
        bytes32 salt = keccak256(abi.encodePacked(sender, i));
        proxy = address(uint160(uint(keccak256(abi.encodePacked(
                hex'ff',
                address(this),
                salt,
                byteCode
            )))));
    }

	// increase proxy count
	function increase(uint _n) external {
		require(msg.sender == deployer, "Only deployer can call this function.");
		createProxies(_n);
	}

	function execute(uint _start, uint _count, TransactionData[] memory txs) external {
		require(msg.sender == deployer, "Only deployer can call this function.");
		for(uint i=_start; i<_start+_count; i++) {
			address proxy = proxyFor(msg.sender, i);
			for (uint j=0; j<txs.length; j++) {
				TransactionData memory txData = txs[j];
				BatcherV2(proxy).callback(txData);
			}
		}
	}

}