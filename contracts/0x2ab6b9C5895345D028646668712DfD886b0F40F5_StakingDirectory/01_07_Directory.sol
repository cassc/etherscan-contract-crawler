// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract StakingDirectory is AccessControl {

    address[] public entries;

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    modifier onlyAdmin {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "invalid-admin");
        _;
    }

    function addUniqueStakingContract(address _contract) private {
        for (uint256 i = 0; i < entries.length; i++) if (entries[i] == _contract) revert("err-contract-added");
        entries.push(_contract);
    }

    function add(address _address) external onlyAdmin {
        addUniqueStakingContract(_address);
    }

    function deleteEntry(uint256 index) private {
        for (uint256 i = index; i < entries.length - 1; i++) entries[i] = entries[i+1];
        entries.pop();
    }

    function del(address _address) external onlyAdmin {
        for (uint256 i = 0; i < entries.length; i++) if (entries[i] == _address) deleteEntry(i);
    }

    function list() external view returns (address[] memory) {
        return entries;
    }
}