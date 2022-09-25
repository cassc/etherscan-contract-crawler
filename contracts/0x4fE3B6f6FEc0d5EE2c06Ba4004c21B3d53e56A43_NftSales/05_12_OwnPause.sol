// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract OwnPause is Ownable, Pausable {
    // List of _authorizedAddressList addresses
    mapping(address => bool) internal _authorizedAddressList;

    event EventGrantAuthorized(address auth_);
    event EventRevokeAuthorized(address auth_);

    modifier isOwner() {
        require(msg.sender == owner(), "OwnPause: not owner");
        _;
    }

    modifier isAuthorized() {
        require(
            msg.sender == owner() || _authorizedAddressList[msg.sender] == true,
            "OwnPause: unauthorized"
        );
        _;
    }

    function checkAuthorized(address auth_) public view returns (bool) {
        require(auth_ != address(0), "OwnPause: invalid auth_ address ");

        return auth_ == owner() || _authorizedAddressList[auth_] == true;
    }

    function grantAuthorized(address auth_) external isOwner {
        require(auth_ != address(0), "OwnPause: invalid auth_ address ");

        _authorizedAddressList[auth_] = true;

        emit EventGrantAuthorized(auth_);
    }

    function revokeAuthorized(address auth_) external isOwner {
        require(auth_ != address(0), "OwnPause: invalid auth_ address ");

        _authorizedAddressList[auth_] = false;

        emit EventRevokeAuthorized(auth_);
    }

    function pause() external isOwner {
        _pause();
    }

    function unpause() external isOwner {
        _unpause();
    }
}