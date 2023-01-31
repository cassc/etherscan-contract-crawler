// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";


contract SigmaSwap {



    address public BUSDaddress;
    address public SIGMAaddress;

    address public SIGMAowner;

    address public SWAPowner;

    bool internal locked;

    constructor (){

        BUSDaddress =  0xeD24FC36d5Ee211Ea25A80239Fb8C4Cfd80f12Ee;  //Substituir pelo endereço real do BUSD
        SIGMAaddress =  0x8272D6AD524da68fc24Fe59aEF9aDDbC95EFbb35;  //substituir sempre que fizer deploy, -> fazer deploy do token sempre antes
        SIGMAowner =  address(this);
        SWAPowner =  msg.sender;

    }

    fallback() external {}
    receive() external payable {}

    modifier noReentrant{
        require(!locked, "No re-entrancy");
        locked = true;
        _;
        locked = false;
    }

    function swap(uint256 amount) external noReentrant returns(bool) 
    {
        require(IERC20(BUSDaddress).transferFrom(msg.sender, SIGMAowner, amount), "Error on payment");
        require(IERC20(SIGMAaddress).transfer(msg.sender, amount), "Error on token transfer");
        return true;
        
    }

    function withdraw(uint256 amount) external returns(bool)
    {
        require(msg.sender == SWAPowner, "You are not the admin");
        require(IERC20(BUSDaddress).transfer(msg.sender, amount), "Error on payment");
        return true;
    }

    function changeAdmin(address newadmin) external returns(bool)
    {
        require(msg.sender == SWAPowner, "You are not the admin");
        SWAPowner = newadmin;
        return true;
    }

}
