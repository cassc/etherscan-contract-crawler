// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "../interfaces/IHECTA.sol";
import "../types/HectagonAccessControlled.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

abstract contract HectagonInvestment is ERC20, HectagonAccessControlled {
    event Reclaim(address from, uint256 amount);
    
    constructor(address authority_, string memory name_, string memory symbol_)
        ERC20(name_, symbol_)
        HectagonAccessControlled(IHectagonAuthority(authority_))
    {}

    function decimals() public view virtual override returns (uint8) {
        return 0;
    }

    function mint(address account_, uint256 amount_) external onlyGovernor {
        _mint(account_, amount_);
    }

    function burn(uint256 amount_) public onlyGovernor {
        _burn(msg.sender, amount_);
    }

    function reclaim(address from_, uint256 amount_) public onlyGovernor {
        _transfer(from_, authority.governor(), amount_);
        emit Reclaim(from_, amount_);
    }
}