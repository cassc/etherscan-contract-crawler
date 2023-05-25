// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.16;

import { ERC20, ERC20Permit } from "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";

contract Spiral is ERC20Permit {
    address public governance;
    mapping (address => bool) public isVault;
    constructor() ERC20("Spiral", "SPR") ERC20Permit("Spiral") {
        governance = msg.sender;
    }

    function mint(address account_, uint256 amount_) external {
        require(isVault[msg.sender], "!vault");
        _mint(account_, amount_);
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    function burnFrom(address account_, uint256 amount_) external {
        _burnFrom(account_, amount_);
    }

    function _burnFrom(address account_, uint256 amount_) internal {
        require(allowance(account_, msg.sender) >= amount_, "ERC20: burn amount exceeds allowance");

        uint256 decreasedAllowance_;
        unchecked {
            decreasedAllowance_ = allowance(account_, msg.sender) - amount_;
        }

        _approve(account_, msg.sender, decreasedAllowance_);
        _burn(account_, amount_);
    }

    function setGovernance(address _governance) external {
        require(msg.sender == governance, "!governance");
        require(_governance != address(0), "wrong address");
        governance = _governance;
    }

    function setVault(address _vault, bool _status) external {
        require(msg.sender == governance, "!governance");
        isVault[_vault] = _status;
    }
}