// SPDX-License-Identifier: MIT

pragma solidity =0.8.15;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./RBAC.sol";

contract MidasToken is ERC20, RBAC {
    uint256 public constant MAX_TOTAL_SUPPLY = 5_000_000e18; // 5,000,000

    constructor(address _admin) ERC20("Midas", "MIDAS") RBAC(_admin) {}

    /**
     * @dev Implement {ERC20._mint} functionality with MINTER_ROLE permission.
     */
    function mint(address _to, uint256 _amount) external onlyRole(MINTER_ROLE) {
        require(totalSupply() + _amount <= MAX_TOTAL_SUPPLY, "MidasToken: MAX_SUPPLY_OVERFLOW");
        _mint(_to, _amount);
    }

    /**
     * @dev Implement {ERC20._burn} functionality with BURNER_ROLE permission.
     */
    function burn(uint256 _amount) external onlyRole(BURNER_ROLE) {
        _burn(msg.sender, _amount);
    }
}