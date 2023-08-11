//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";

contract GenesisPayments is AccessControl, PaymentSplitter {
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    constructor(
        address[] memory artists,
        uint256[] memory shares
    ) payable PaymentSplitter(artists, shares)  
    {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(OPERATOR_ROLE, msg.sender);
    }

    function releasableByArtist(address account) public view returns (uint256) {
        return super.releasable(account);
    }

    function releaseByArtist() public {
        super.release(payable(msg.sender));
    }

    function withdraw(address payable beneficiary) public onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 amount = address(this).balance;
        (bool success, ) = payable(beneficiary).call{value: amount}("");
        require(success, "Failed to withdraw");
    }
}