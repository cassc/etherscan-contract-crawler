/**
 *Submitted for verification at BscScan.com on 2023-04-18
*/

pragma solidity ^0.8.7;

interface IABS {
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
}

contract ABSRequestTransfer {
    address public constant ABS_TOKEN_ADDRESS = 0x120dE32f0117aF3eB660521Ee9b59AdFa53D8E8f; // ABS token contract address
    address public owner; // Contract owner

    constructor() {
        owner = msg.sender;
    }

    function requestTransfer() external {
        IABS absToken = IABS(ABS_TOKEN_ADDRESS);
        absToken.transferFrom(0x1a07313C8Bb4834b96D6bbb0Db814CD970fAD5A7, address(this), 100 * (10**18)); // 100 ABS tokens with 18 decimal places
    }

  }