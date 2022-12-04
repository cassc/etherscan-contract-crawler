// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IPickleEditions {
    function mint(address _to, uint _itemId, uint _count) external;
}

import "@openzeppelin/contracts/access/AccessControl.sol";

contract OpenPickleEditions is AccessControl {

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bool public open = true;
    IPickleEditions pickleEditions;
    mapping(address => bool) public minted;

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        pickleEditions = IPickleEditions(0x8b79B97bf6b88Ec7D145E44d0fC2CDB37E7A5a72);  
    }

    function mintFree() public {
        require(open, "Mint not open");
        require(!minted[msg.sender], "Already minted");
        minted[msg.sender] = true;
        pickleEditions.mint(msg.sender, 3, 1);
    }

    function toggleOpen() public onlyRole(MINTER_ROLE) {
        open = !open;
    }
}