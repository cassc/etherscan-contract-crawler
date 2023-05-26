// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import "../shared/libraries/SafeMath.sol";
import "../shared/interfaces/IMVD.sol";
import "../shared/types/ERC20Permit.sol";
import "../shared/types/MetaVaultAC.sol";
import "../MetaVaultAuthority.sol";

contract MVD is ERC20Permit, MetaVaultAC {
    using SafeMath for uint256;

    constructor(address _authority) ERC20("Metavault DAO", "MVD", 9) ERC20Permit() MetaVaultAC(IMetaVaultAuthority(_authority)) {}

    function mint(address account_, uint256 amount_) external onlyVault {
        _mint(account_, amount_);
    }

    function burn(uint256 amount) public virtual {
        _burn(msg.sender, amount);
    }

    function burnFrom(address account_, uint256 amount_) public virtual {
        _burnFrom(account_, amount_);
    }

    function _burnFrom(address account_, uint256 amount_) public virtual {
        uint256 decreasedAllowance_ = allowance(account_, msg.sender).sub(amount_, "ERC20: burn amount exceeds allowance");

        _approve(account_, msg.sender, decreasedAllowance_);
        _burn(account_, amount_);
    }
}