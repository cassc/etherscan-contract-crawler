pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";

abstract contract WonderlandAccessControl is AccessControl {
    bytes32 internal constant OWNER_ROLE = 0xb19546dff01e856fb3f010c267a7b1c60363cf8a4664e21cc89c26224620214e;
    bytes32 internal constant MINTER_ROLE = 0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6; // keccak256(abi.encodePacked("MINTER_ROLE"));
    bytes32 internal constant HANDLER_ROLE = 0x8ee6ed50dc250dbccf4d86bd88d4956ab55c7de37d1fed5508924b70da11fe8b;

    address internal _owner_ = 0x19baC9aFFF2cD4DfCF40f42EE0423009Cbe9da9e;

    bool public isPaused;

    modifier whenNotPaused {
        require(!isPaused, "Wonder Game Character Inventory is paused");
        _;
    }

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _owner_);
        _setupRole(OWNER_ROLE, _owner_);
    }

    function pause() public onlyRole(OWNER_ROLE) {
        isPaused = true;
    }

    function unpause() public onlyRole(OWNER_ROLE) {
        isPaused = false;
    }
}