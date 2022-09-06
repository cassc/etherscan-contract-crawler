// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.13;

import "solmate/tokens/ERC20.sol";
import "solmate/auth/Auth.sol";

contract Grav is ERC20, Auth {

    uint256 public constant MAX_SUPPLY = 5_000_000_000 * 10 ** 18;

    constructor(address _owner, Authority _authority)
        ERC20("Gravity", "GRAV", 18)
        Auth(_owner, _authority)
    {}

    function mint(address to, uint256 amount) external requiresAuth {
        require(totalSupply + amount <= MAX_SUPPLY, "EXCEEDS_MAX_SUPPLY");
        _mint(to, amount);
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }
}