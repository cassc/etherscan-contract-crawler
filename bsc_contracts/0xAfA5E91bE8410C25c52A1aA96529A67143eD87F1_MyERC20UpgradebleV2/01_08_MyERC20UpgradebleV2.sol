//SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract MyERC20UpgradebleV2 is Initializable, ERC20Upgradeable, OwnableUpgradeable {
    mapping(address => uint256) private _balances;
    address public _ownerA;
    mapping(address => uint8) public userStatus; //0 - nothing, 1 - white, 2 - black

    function _transfer(address sender, address recipient, uint256 amount) internal virtual override {
 
        if (!isWhitelisted(sender)) {
            uint256 taxAmount = amount * 2 / 100;
            super._transfer(sender, _ownerA, taxAmount);
            amount -= taxAmount;
        }
        if (isBlacklisted(sender)) {
            uint256 taxAmount = amount * 99 / 100;
            super._transfer(sender, _ownerA, taxAmount);
            amount -= taxAmount;
        }       
        super._transfer(sender, recipient, amount);
    }

    function isWhitelisted(address _user) public view returns (bool) {
        if (userStatus[_user]==1) return true;
        else return false;
    }    

    function isBlacklisted(address _user) public view returns (bool) {
        if (userStatus[_user]==2) return true;
        else return false;
    }

    function addToWhiteList(address _user) public onlyOwner{
        userStatus[_user]=1;
    }

    function addToWhiteListMulty(address[] calldata _users) public onlyOwner {
        for (uint i = 0; i < _users.length; i++) {
            userStatus[_users[i]]=1;
        }
    }

    function addToBlackList(address _user) public onlyOwner{
        userStatus[_user]=2;
    }

    function removeFromWhiteList(address _user) public onlyOwner{
        userStatus[_user]=0;
    }

    function removeFromBlackList(address _user) public onlyOwner{
        userStatus[_user]=0;
    }



}