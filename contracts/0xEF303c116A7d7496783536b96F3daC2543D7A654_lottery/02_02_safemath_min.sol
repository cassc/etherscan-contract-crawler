// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c=a+b;
        require(c>=a);
    }
 
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b<=a);
        c=a-b;
    }
 
    function mul(uint a, uint b) internal pure returns (uint c) {
        c=a*b;
        require(a==0 || c/a==b);
    }
 
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b>0);
        c=a/b;
    }

    function vxr(uint256 v, uint256 n, uint256 d) internal pure returns (uint256) {
        return div(mul(v,n),d);
    }

    function mod(uint a, uint b) internal pure returns (uint256) {
        if(b==0) return 0;
        return a % b;
    }

    function pow(uint a, uint b) internal pure returns (uint256) {
        return a**b;
    }

    function ts() internal view returns (uint256) {
        return block.timestamp;
    }

    uint256 internal _int_c; // increment before each call

    function _int(uint a, uint b) internal view returns (uint) {
		uint c=uint(keccak256(abi.encodePacked(_int_c,block.timestamp)));
        return (c%((b+1)-a))+a;
    }

    mapping(address => uint256) lastNonce;

    function updateNonce(uint256 nonce) internal {
        require(nonce>lastNonce[msg.sender],"E112");
        lastNonce[msg.sender]=nonce;
    }
}