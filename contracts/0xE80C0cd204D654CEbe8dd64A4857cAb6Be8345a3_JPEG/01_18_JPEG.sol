// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * JPEG - governance token
 */
contract JPEG is ERC20Votes, AccessControl {

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor(uint256 totalSupply)
        ERC20("JPEG\xE2\x80\x99d Governance Token", "JPEG")
        ERC20Permit("JPEG")
    {
        _mint(msg.sender, totalSupply);
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function mint(address to, uint256 amount) external {
        require(
            hasRole(MINTER_ROLE, _msgSender()),
            "JPEG: must have minter role to mint"
        );
        _mint(to, amount);
    }
}