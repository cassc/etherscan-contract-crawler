// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

contract HoneyDeluxeToken is ERC20, AccessControlEnumerable {
    uint256 public constant MAX_SUPPLY = 35007150000000000000000000;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    constructor() ERC20("Honey Deluxe Token", "HONEYD") {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(BURNER_ROLE, _msgSender());
    }

    function mint(address _owner, uint256 _amount) external {
        require(hasRole(MINTER_ROLE, _msgSender()), "Missing MINTER_ROLE");

        if (totalSupply() + _amount > MAX_SUPPLY) _amount = MAX_SUPPLY - totalSupply();
        _mint(_owner, _amount);
    }

    function burn(address _owner, uint256 _amount) external {
        require(hasRole(BURNER_ROLE, _msgSender()), "Missing BURNER_ROLE");

        _burn(_owner, _amount);
    }

    function maxSupply() external pure returns (uint256) {
        return MAX_SUPPLY;
    }
}