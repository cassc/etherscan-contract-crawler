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

        BUSDaddress =  0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
        SIGMAaddress =  0xf905737F715Ef88e39eC13e720590e78D503b32A;
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
