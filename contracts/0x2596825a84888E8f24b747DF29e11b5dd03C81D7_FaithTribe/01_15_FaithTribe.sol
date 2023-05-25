// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

// No SafeMath needed for Solidity 0.8+
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract FaithTribe is ERC20Burnable, ERC20Snapshot, AccessControl {
    bytes32 public constant SNAPSHOT_ROLE = keccak256("SNAPSHOT_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    bool public minted = false;

    uint256 public immutable maxSupply;

    // accepts initial supply in whole numbers and adds decimal places of the token automatically
    constructor(uint256 _maxSupply, address adminRole, address snapshotRole, address minterRole) ERC20("Faith Tribe", "FTRB") {
        _setupRole(DEFAULT_ADMIN_ROLE, adminRole);
        _setupRole(SNAPSHOT_ROLE, snapshotRole);
        _setupRole(MINTER_ROLE, minterRole);

        maxSupply = _maxSupply;
    }
    
    // Can only mint once to whatever was set in the constructor
    function mint() public onlyRole(MINTER_ROLE) {
        require(!minted, "ALREADY_MINTED_MAX_SUPPLY");
        
        minted = true;
        _mint(_msgSender(), maxSupply);
    }

    function snapshot() public onlyRole(SNAPSHOT_ROLE) {
        _snapshot();
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        override(ERC20Snapshot, ERC20)
    {
        super._beforeTokenTransfer(from, to, amount);
    }
}