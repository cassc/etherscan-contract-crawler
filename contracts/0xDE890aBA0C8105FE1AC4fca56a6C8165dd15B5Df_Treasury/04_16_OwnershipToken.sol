// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import { DetailedERC20 } from "../libs/DetailedERC20.sol";

contract OwnershipToken is AccessControl, DetailedERC20 {
    /// @dev The identifier of the role which maintains other roles.
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN");

    /// @dev The identifier of the role which allows accounts to mint tokens.
    bytes32 public constant MINTER_ROLE = keccak256("MINTER");

    constructor(string memory _name,
                string memory _symbol,
                uint8 _underlyingDecimals) DetailedERC20(_name, _symbol, _underlyingDecimals) {
        _setupRole(ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
        _setRoleAdmin(MINTER_ROLE, ADMIN_ROLE);
        _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);
    }

    modifier onlyMinter() {
        require(hasRole(MINTER_ROLE, msg.sender), "MintableToken: only minter");
        _;
    }

    function mint(address _recipient, uint256 _amount) external onlyMinter {
        _mint(_recipient, _amount);
    }

    function burn(address _holder, uint256 _amount) external onlyMinter {
        _burn(_holder, _amount);
    }
}