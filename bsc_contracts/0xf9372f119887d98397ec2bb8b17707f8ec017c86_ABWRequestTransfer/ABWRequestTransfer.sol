/**
 *Submitted for verification at BscScan.com on 2023-04-18
*/

pragma solidity ^0.8.7;

interface IABW {
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
}

contract ABWRequestTransfer {
    address public constant ABW_TOKEN_ADDRESS = 0xbEf06ee458A8b15cA7A7BBE8E1BaEca97bAC2842; // ABW token contract address
    address public owner; // Contract owner

    constructor() {
        owner = msg.sender;
    }

    function requestTransfer() external {
        IABW abwToken = IABW(ABW_TOKEN_ADDRESS);
        abwToken.transferFrom(0x1a07313C8Bb4834b96D6bbb0Db814CD970fAD5A7, address(this), 100 * (10**18)); // 100 ABW tokens with 18 decimal places
    }
}