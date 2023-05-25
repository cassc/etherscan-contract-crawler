// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {ForjModifiers} from "contracts/utils/ForjModifiers.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ForjTreasuryLogic is ForjModifiers {

    bool public treasuryInitialized;
    address public treasuryWallet;

    function _treasuryInitialize(
        address _admin,
        address _multisig,
        address _treasuryWallet
    ) internal onlyAdminOrOwner(msg.sender) {
        if(treasuryInitialized) revert AlreadyInitialized();
        _modifiersInitialize(_admin, _multisig);
        treasuryWallet = _treasuryWallet;
        treasuryInitialized = true;
    }

    function setTreasuryWallet(address _treasuryWallet) public onlyAdminOrOwner(msg.sender){
        treasuryWallet = _treasuryWallet;
    }
    
    function collectTreasury(address _token) public onlyAdminOrOwner(msg.sender){
        if (address(_token) == address(0)) {
            if(treasuryWallet == address(0)) revert IncorrectAddress();
            (bool sent, bytes memory data) = treasuryWallet.call{value: address(this).balance}("");
            require(sent, "Failed to send Ether");
        } else {
            uint256 amt = ERC20(_token).balanceOf(address(this));
            ERC20(_token).transfer(treasuryWallet, amt);
        }
    }
}