// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "ERC20.sol";

contract Sidus is ERC20 {

    uint256 constant public MAX_SUPPLY = 30_000_000_000e18;
    address public deployer;

    constructor(address initialKeeper)
    ERC20("SIDUS", "SIDUS")
    { 
        _mint(initialKeeper, MAX_SUPPLY);
        deployer = _msgSender();
    }

     /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) external {
        _burn(_msgSender(), amount);
    }


    /**
     * @dev Deployer can claim any tokens that transfered to this contract 
     * address for prevent users confused
     */
    function reclaimToken(ERC20 token) external {
        require(_msgSender() == deployer, "Only for deployer");
        require(address(token) != address(0));
        uint256 balance = token.balanceOf(address(this));
        token.transfer(msg.sender, balance);
    }
}