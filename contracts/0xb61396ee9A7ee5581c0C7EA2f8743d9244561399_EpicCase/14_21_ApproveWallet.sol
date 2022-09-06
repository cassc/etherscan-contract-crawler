// // SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract ApproveWallet is Ownable {
    address private approveWallet;

    modifier onlyApproveWallet() {
        require(msg.sender == approveWallet, "ApproveWallet: caller is not the approve wallet");
        _;
    }

    function addApproveWallet(address _approveWallet) public onlyOwner {
        approveWallet = _approveWallet;
    }

    function deleteApproveWallet() public onlyOwner {
        approveWallet = address(0);
    }
}