// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import "openzeppelin-contracts-upgradeable/access/OwnableUpgradeable.sol";

contract AccessUpgradeable is OwnableUpgradeable {

    mapping(address => bool) public isAdmin;

    function __Access_init() internal onlyInitializing {
        //__Ownable_init();
    }

    modifier onlyAdmin() {
        require(isAdmin[msg.sender] || msg.sender == owner(), "Access: caller is not admin");
        _;
    }

    function editAdmin(address admin, bool b) external onlyOwner {
        isAdmin[admin] = b;
    }

    function editAdmins(address[] calldata admins, bool b) external onlyOwner {
        for(uint256 i = 0; i < admins.length; i++) {
            isAdmin[admins[i]] = b;
        }
    }

    uint256[49] private __gap;
}