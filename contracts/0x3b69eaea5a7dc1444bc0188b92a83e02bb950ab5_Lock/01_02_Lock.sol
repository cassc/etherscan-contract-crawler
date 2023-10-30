// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// import "@openzeppelin/openzeppelin-contracts/token/ERC20/ERC20.sol";
// import erc20 interface from openzeppelin
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract Lock {
    bool public unlocked;
    address payable public owner;
    address payable private benefactor;

    event Withdrawal(uint amount, uint when);
    event Toggle(bool unlocked);
    event UpdateBenefactor(address benefactor);


    constructor() payable {
        owner = payable(msg.sender);
        unlocked = false;
    }

    function withdraw() public {
        require((msg.sender == owner) || (msg.sender == benefactor), "You aren't the owner nor benefactor");
        require(unlocked == true);
        emit Withdrawal(address(this).balance, block.timestamp);

        IERC20 zapContract = IERC20(0x6781a0F84c7E9e846DCb84A9a5bd49333067b104);
        
        zapContract.approve(address(this), 2**256 - 1);
        zapContract.transferFrom(address(this), msg.sender, zapContract.balanceOf(address(this)));

    }

    function toggle() public returns (bool) {
        require(msg.sender == owner , "You aren't the owner");
        emit Toggle(unlocked);
        unlocked = !unlocked;
        return unlocked;
    }

    function getBenefactor() public view returns (address) {
        return(benefactor);
    }

    function getUnlocked() public view returns (bool) {
        return(unlocked);
    }

    function setBenefactor(address payable _benefactor) public {
        require(msg.sender == owner, "You aren't the owner");
        require(_benefactor != address(0));
        benefactor = _benefactor;
        emit UpdateBenefactor(benefactor);
    }
}