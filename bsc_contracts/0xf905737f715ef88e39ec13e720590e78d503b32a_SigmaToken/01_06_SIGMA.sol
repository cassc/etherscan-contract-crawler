// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)
// testando git

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./ERC20.sol";
import "./Context.sol";
import "./IERC20Metadata.sol";


contract SigmaToken is ERC20{

    address SigmaAdminAddress;

    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) {
        SigmaAdminAddress = msg.sender;
    }

    function mint(address account, uint256 amount) external{
        require(msg.sender == SigmaAdminAddress, "Only the admin should mint new tokens");
        _mint(account, amount);

    }
    
    function burn(address account, uint256 amount) external{
        require(msg.sender == SigmaAdminAddress, "Only the admin should mint new tokens");
        _burn(account, amount);
    }

    function changeAdmin(address newadmin) external returns(bool)
    {
        require(msg.sender == SigmaAdminAddress, "You are not the admin");
        SigmaAdminAddress = newadmin;
        return true;
    }

    

}
