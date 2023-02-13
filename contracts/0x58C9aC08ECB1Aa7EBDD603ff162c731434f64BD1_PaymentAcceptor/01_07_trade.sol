// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.17;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract PaymentAcceptor is Pausable, Ownable{
    address public USDTaddress;

    event BuyOPCHfromUSDT(address from, uint256 amount);
    event BuyOPCH(address from, uint256 amount);

    constructor(address _address) {
        require(address(_address) != address(0), "USDT tokenAddress cannot be address 0");
        USDTaddress = _address;
    }

    function buyOPCHfromUSDT(uint256 _value) external payable {
        require(msg.sender != address(0));
        require(_value > 0);
        // Transfer ERC-20 tokens from msg.sender to the contract
        require(ERC20(USDTaddress).transferFrom(_msgSender(), address(this), _value),"Token transfer failed!");
        emit BuyOPCHfromUSDT(msg.sender, _value);
    }

    function buyOPCH() external payable {
        require(msg.sender != address(0));
        require(msg.value > 0);
        emit BuyOPCH(msg.sender, msg.value);
    }

    function withdrawUSDT(uint256 _value) external onlyOwner{
        require(_value > 0);
        // Transfer ERC-20 tokens from contract to msg.sender
        ERC20(USDTaddress).transfer(msg.sender, _value);
    }

    function withdrawETH(uint256 _value) external onlyOwner{
        require(_value > 0);
        require(address(this).balance >= _value);
        address payable to = payable(msg.sender);
        to.transfer(_value);
    }

    /* Dont accept eth*/  
    receive() external payable {
        revert("The contract does not accept direct payment, please use the depositETH method.");
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}