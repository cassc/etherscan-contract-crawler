// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

abstract contract Ownable {
    error NotAdmin();

    address public admin;

    modifier onlyOwner() {
        if (msg.sender != admin) {
            revert NotAdmin();
        }
        _;
    }

    function changeAdmin(address newAdmin) external onlyOwner {
        admin = newAdmin;
    }
}