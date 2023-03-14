// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol" ;

contract HydroxylToken is ERC20PresetMinterPauser {

    mapping(address => bool) public whiteAddr;
    bool public isFans = false ;

    constructor(uint256 initSupply) ERC20PresetMinterPauser("Hydroxyl Token", "HYT") {
        whiteAddr[address(0x00)] = true ;
        whiteAddr[_msgSender()] = true ;
        mint(_msgSender(), initSupply) ;
    }

    function addWhiteAddr(address [] memory addrs, bool status) external onlyRole(DEFAULT_ADMIN_ROLE)  {
        for(uint256 i = 0; i < addrs.length; i++) {
            whiteAddr[addrs[i]] = status ;
        }
    }

    function setFans(bool newFans) external onlyRole(DEFAULT_ADMIN_ROLE)  {
        isFans = newFans ;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20PresetMinterPauser) {

        if(isFans) {
            if(whiteAddr[from] || whiteAddr[to] || whiteAddr[_msgSender()]) {
                super._beforeTokenTransfer(from, to, amount);
            } else {
                require(false, "Illegal transfer operation") ;
            }
        } else {
            super._beforeTokenTransfer(from, to, amount);
        }
    }

}