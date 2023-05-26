// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import '@openzeppelin/contracts/access/Ownable.sol';
import "./Zogi.sol";

contract ZogiOwner is Ownable{
    
    ZOGI public zogi;
    
    constructor(address zogiAddress_){
        zogi = ZOGI(zogiAddress_);
    }

    function approve(address spender, uint256 amount) public onlyOwner returns (bool){
        return zogi.approve(spender, amount);
    }

    function blacklistUpdate(address user, bool value)public onlyOwner{
        zogi.blacklistUpdate(user,value);
    }

    function increaseAllowance(address spender, uint256 addedValue)public onlyOwner returns (bool){
        return zogi.increaseAllowance(spender, addedValue);
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public onlyOwner returns (bool){
        return zogi.decreaseAllowance(spender, subtractedValue);
    }

    function mint(address account_, uint256 amount_)public onlyOwner{
        zogi.mint(account_,amount_);
    }

    function burn(uint256 amount_) public onlyOwner{
        zogi.burn(amount_);
    }

    function pause() public onlyOwner{
        zogi.pause();
    }
    function unpause() public onlyOwner{
        zogi.unpause();
    }

    function setAdmin(address admin, bool enabled) public onlyOwner{
        zogi.setAdmin(admin, enabled);
    }

    function snapShot() public onlyOwner{
        zogi.snapShot();
    }

    function transfer(address to, uint256 amount) public onlyOwner returns (bool){
        return zogi.transfer(to, amount);
    }

    function transferFrom(address from, address to, uint256 amount) public onlyOwner returns (bool){
        require(!zogi.isBlackListed(from), "Owner cannot transfer blacklisted funds");
        require(!zogi.isBlackListed(to), "Owner cannot transfer blacklisted funds");
        return  zogi.transferFrom(from, to, amount);
    }

}