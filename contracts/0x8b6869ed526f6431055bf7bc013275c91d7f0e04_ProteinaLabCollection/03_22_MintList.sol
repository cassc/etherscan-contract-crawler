// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

contract MintList is AccessControlEnumerable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");


    uint256 minters_limit = 0;
    constructor(uint256 _minters_limit) {
        minters_limit = _minters_limit;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function subscribe() public {
        if(minters_limit > 0) {
            require(minters_limit > getCountMinters(), "MintList: this list reached the limit of members");
        }
        _setupRole(MINTER_ROLE, _msgSender());
    }

    function getCountMinters()  public view returns (uint256) {
        return getRoleMemberCount(MINTER_ROLE);
    }

    function isMinter(address minter) public view returns (bool) {
        return hasRole(MINTER_ROLE, minter);
    }
}