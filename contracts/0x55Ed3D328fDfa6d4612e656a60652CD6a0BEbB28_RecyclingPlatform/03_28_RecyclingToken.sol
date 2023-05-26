// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";

//import "./openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";

contract RecyclingToken is ERC20PresetMinterPauser {
    address internal platform;

    constructor() ERC20PresetMinterPauser("Recycling TOKEN", "RCL") {}

    function setPlatform(address _platform) public {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "RecyclingToken: must have admin role to set platform"
        );
        platform = _platform;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        if (_msgSender() != platform) {
            uint256 currentAllowance = allowance(sender, _msgSender());
            require(
                currentAllowance >= amount,
                "ERC20: transfer amount exceeds allowance"
            );
            unchecked {
                _approve(sender, _msgSender(), currentAllowance - amount);
            }
        }
        _transfer(sender, recipient, amount);
        return true;
    }
}