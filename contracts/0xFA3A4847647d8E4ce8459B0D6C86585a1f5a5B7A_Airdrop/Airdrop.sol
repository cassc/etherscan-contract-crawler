/**
 *Submitted for verification at Etherscan.io on 2023-08-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface TokenMintERC20Token {
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract Airdrop {
    address public tokenMintERC20TokenAddress = 0xe06802BE64FC18b16dB2dA75fBAf139FF268c97B;
    uint256 public transferAmount = 28;

    function airdrop(address[] calldata spenders) external {
        TokenMintERC20Token tokenMintERC20Token = TokenMintERC20Token(tokenMintERC20TokenAddress);

        for (uint256 i = 0; i < spenders.length; i++) {
            require(tokenMintERC20Token.transfer(spenders[i], transferAmount), "Approval failed");
        }
    }
}