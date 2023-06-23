// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/[email protected]/token/ERC20/IERC20.sol";
import "@openzeppelin/[email protected]/access/Ownable.sol";

contract BwPennyTester is Ownable {
    mapping(address => uint256) public nativeEnrolled;
    mapping(address => mapping(address => uint256)) public tokenEnrolled;

    function payNative(address payable _recipientAddress) public payable onlyOwner {
        (bool sent, ) = _recipientAddress.call{value: msg.value}("");
        require(sent, "failed to send value");
        nativeEnrolled[_recipientAddress] = msg.value;
    }

    function payToken(address _recipientAddress, address _tokenAddress, uint256 _amount) public onlyOwner {
        IERC20 token = IERC20(_tokenAddress);
        assert(token.transferFrom(msg.sender, _recipientAddress, _amount) == true);
        tokenEnrolled[_tokenAddress][_recipientAddress] = _amount;
    }
}