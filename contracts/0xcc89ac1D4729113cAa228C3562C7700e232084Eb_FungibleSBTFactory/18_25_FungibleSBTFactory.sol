// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <0.9.0;

import "../tokens/FungibleSBT.sol";
import "../seller/TicketSeller.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract FungibleSBTFactory is Ownable, AccessControl, Pausable {
    bytes32 public ADMIN = "ADMIN";

    TicketSeller public seller;
    string public baseContractURI;

    event Created(address indexed collection, address indexed creator);

    constructor() {
        _grantRole(ADMIN, msg.sender);
    }

    function create(string memory name, string memory symbol)
        external
        whenNotPaused
    {
        FungibleSBT collection = new FungibleSBT(
            name,
            symbol,
            baseContractURI,
            msg.sender,
            address(seller),
            owner()
        );
        emit Created(address(collection), msg.sender);
    }

    function setSeller(address value) external onlyRole(ADMIN) {
        seller = TicketSeller(value);
    }

    function setBaseContractURI(string memory value) external onlyRole(ADMIN) {
        baseContractURI = value;
    }

    // ==================================================================
    // operations
    // ==================================================================
    function grantRole(bytes32 role, address target) public override onlyOwner {
        _grantRole(role, target);
    }

    function revokeRole(bytes32 role, address target)
        public
        override
        onlyOwner
    {
        _revokeRole(role, target);
    }

    function pause() external onlyRole(ADMIN) {
        _pause();
    }

    function unpause() external onlyRole(ADMIN) {
        _unpause();
    }
}