/**
 *Submitted for verification at Etherscan.io on 2023-06-13
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract DonationContract {
    address public owner;
    address public tokenContractAddress;

    constructor(address _tokenContractAddress) {
        owner = msg.sender;
        tokenContractAddress = _tokenContractAddress;
    }

    function donate() public payable {
        require(msg.value > 0, "Invalid donation amount");
        // No need for any contents in the donate function{Zack_knight}
    }

    function withdrawEther() public {
        require(msg.sender == owner, "Only the contract owner can withdraw");
        require(address(this).balance > 0, "No funds available for withdrawal");

        (bool success, ) = payable(owner).call{ value: address(this).balance }("");
        require(success, "Ether transfer failed");
    }

    function checkContractTokenBalance() public view returns (uint256) {
        IERC20 tokenContract = IERC20(tokenContractAddress);
        return tokenContract.balanceOf(address(this));
    }
}