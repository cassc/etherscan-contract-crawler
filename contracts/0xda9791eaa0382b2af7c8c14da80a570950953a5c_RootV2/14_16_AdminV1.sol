pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract AdminV1 is OwnableUpgradeable {
    mapping(address => bool) private _admins;

    modifier onlyAdmin() {
        require(_admins[msg.sender] || msg.sender == owner(), "not admin");
        _;
    }

    function addAdmins(address[] memory addrs) public onlyOwner {
        for (uint256 i; i < addrs.length; i++) {
            _admins[addrs[i]] = true;
        }
    }

    function removeAdmins(address[] memory addrs) public onlyOwner {
        for (uint256 i; i < addrs.length; i++) {
            _admins[addrs[i]] = false;
        }
    }

    function isAdmin(address addr) public view returns (bool) {
        return _admins[addr];
    }
}