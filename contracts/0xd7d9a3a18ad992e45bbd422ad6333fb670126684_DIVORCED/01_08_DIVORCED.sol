// SPDX-License-Identifier: MIT

/*
 ######  #     # ####### ######   #####  ######  
 #     # #     # #     # #     # #     # #     # 
 #     # #     # #     # #     # #       #     # 
 #     # #     # #     # ######  #       #     # 
 #     #  #   #  #     # #   #   #       #     # 
 #     #   # #   #     # #    #  #     # #     # 
 ######     #    ####### #     #  #####  ######  
A memecoin for every mfer who ever got their heart broke or their shit took.
*/

pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract DIVORCED is ERC20, ERC20Burnable, Pausable, Ownable {

    error NoZeroTransfers();
    error ContractPaused();
    error MaxExceeded();

    uint256 public maxAmount = 808000000000 * 10 ** decimals();

    constructor() ERC20("DIVORCED", "DVORCD") {
        _mint(msg.sender, 808000000000 * 10 ** decimals());
    }

    function setMaxAmount(uint256 _maxAmount) external onlyOwner {
        maxAmount = _maxAmount;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfer(address sender, address recipient, uint256 amount) internal override {
        if (paused() && owner() != sender) {revert ContractPaused();}
        if (amount == 0) {revert NoZeroTransfers();}
        if (amount > maxAmount && owner() != sender)  {revert MaxExceeded();}
        super._beforeTokenTransfer(sender, recipient, amount);
    }
}