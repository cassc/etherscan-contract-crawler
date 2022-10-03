// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/*
$PLTNM TOKEN
2022 Platinum Labs
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@&&&%%%%%%%%%%%###########((@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@&&&&&&&&&&&&%%%%%%%%%%%%########@@@@@@@@@@@@@@@(((((((@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@&&&&&&&&&&&%%%%%%%%%%%%%%###&@@@@@@@&&&&@@@@@@@@((((((((((((@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@&&&&&&&&&&&%%@@@@@@@@@@@@@@@@@@@&&&&&&&&&@@@@@@@@((((((((((((((@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@&&&&&&&&&&@@@@@@@@@@@@@@@@@@@@@@&&&&&@@@@@&&&&&&&&&&&&(((((((((((((((((@@@@@@@@@@@@@@@@@@
@@@@@@@@@&&&&&&&&&@@@@@@@@@@@@@@@@@@@@@@@&&&&&@@@@@@@@@&&&&&&&&&&&&&@(((((((((((((((((@@@@@@@@@@@@@@
@@@@@@@@&&&&&&&&@@@@@@@@@@@@@@@@@@@@@@&&&&&@@@@@@@@@@@@@@@&&&&&&&&&&&&@@@@(((((((((((((((@@@@@@@@@@@
@@@@@@@@&&&&&&&@@@@@@@@@@@@@@@@@@@@@&&&&&@@@@@@@@@@@@@@@@@@@&&&&&&%%%%%%%@@@@(((((((((((((((@@@@@@@@
@@@@@@@@&&&&&&&@@@@@@@@@@@@@@&&&&&&&&&@@@@@@@@@@@@@@@@@@@@@@@@@&&&&%%%%%%%%@@@@@(((((((((((((((@@@@@
@@@@@@@@@&&&&&&&@@@@@@@&&&&&&&&&&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&&&%%%%%%%#@@@@(((((((((((((((@@@
@@@@@@@@@@&&&&&&&@@@@&&&&&&&&&&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&&&########@@@@((((((((((((((@@
@@@@@@@@@@@&&&&&&&&@@@@&&&&&&&&&&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%%%&########@@@@@@@((((((((((((((@
@@@@@@@@@@@@@@&&&&&&&@@@@@&&&&&&%%%%%%&@@@@@@@@@@@@@@@@@@@@@@@%%%%%########@@@@@@@@@@@((((((((((((((
@@@@@@@@@@@@@@@@&&&&&&&&@@@@%%%%%%%%%%%%%@@@@@@@@@@@@@@@@@@@#############@@@@@@@@@@@@@((((((((((((((
@@@@@@@@@@@@@@@@@@@&&&&&&&&@@@@%%%%%%%%%%%%@@@@@@@@@@@@@@%#########(((@@@@@@@@@@@@@@@(((((((((((((((
@@@@@@@@@@@@@@@@@@@@@@@&&&&&&&&&@%%%##########@@@@@@@@@#####((((((((@@@@@@@@@@@@@@@(((((((((((((((((
@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&&&&&&&&##########@@@@@((((((((((((@@@@@@@@@@@@@@%(((((((((((((((((((@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&&&&&&&&&&&%((((((((((((((((@@@@@@@@@@((((((((((((((((((((((((@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&&&&&&&&&&&%%%%%%%%%%%%%##########((((((((((((((((((((((((@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&&&&&&&&&&%%%%%%%%%%%%%##########((((((((((((((((((&@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&%%%%%%%%%%%##########((((((((((((((@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@/////@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 */

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";

contract Platinum is ERC20, ERC20Burnable, ERC20Snapshot, AccessControl, Pausable, ERC20Permit, ERC20Votes {

    bytes32 public constant SNAPSHOT_ROLE = keccak256("SNAPSHOT_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");


    uint256 public MAX_SUPPLY = 100000000;
    uint256 public totalMinted = 0;


    constructor() ERC20("Platinum", "$PLTNM") ERC20Permit("Platinum") {
        
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(SNAPSHOT_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);

    }

    function snapshot() public onlyRole(SNAPSHOT_ROLE) {
        _snapshot();
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        require (totalMinted <= MAX_SUPPLY, "Token Max Supply Exceeded");
        require ((totalMinted + amount) <= MAX_SUPPLY, "Token Max Supply Exceeded");
        totalMinted += amount;
        _mint(to, amount);
    }


     function adjustMaxSupply(uint256 amount) public onlyRole(DEFAULT_ADMIN_ROLE){
        require (amount>=totalMinted, "New Max must not be lesser than total minted amount");
        MAX_SUPPLY = amount;
     }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override(ERC20, ERC20Snapshot)
    {
        super._beforeTokenTransfer(from, to, amount);
    }


    // The following functions are overrides required by Solidity.

    function _afterTokenTransfer(address from, address to, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(address to, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._mint(to, amount);
    }

    function _burn(address account, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._burn(account, amount);
    }

     function decimals() public view virtual override returns (uint8) {
        return 0;
    }
}