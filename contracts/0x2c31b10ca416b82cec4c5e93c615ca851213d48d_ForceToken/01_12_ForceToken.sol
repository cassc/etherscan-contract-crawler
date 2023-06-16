//SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20Snapshot.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";


contract ForceToken is AccessControl, ERC20Snapshot {

    bytes32 public constant SNAPSHOT_ROLE = keccak256("SNAPSHOT_ROLE");

    constructor(string memory name, string memory symbol)
        ERC20(name, symbol)
    {
        // Roles
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(SNAPSHOT_ROLE, msg.sender);

        // Initial minting
        _mint(msg.sender, 100000000 ether);
    }


    function snapshot()
        public
        returns (uint256)
    {
        require(hasRole(SNAPSHOT_ROLE, msg.sender), "ForceToken: must have snapshot role to call snapshot");

        return _snapshot();
    }
}