pragma solidity ^0.8.7;
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";


contract GAT_Opensea is Ownable{
    uint256 public balance;
    uint256 public royaltyBalance;
    uint256 public gatBalance;
    address public royaltyAddress=0x02D7d23Ca050B0AeC73310DF298a179ACE9d0C7b;
    address public gatAddress=0x2171f1dA3083E848BABeB7F478B871d0384C00aA;
    uint256 public royaltyPercentage=50;
    uint256 public gatPercentage=50;


    function setRoyaltyAddress(address royalty_address) public onlyOwner {
        royaltyAddress = royalty_address;
    }

    
    function setGatAddress(address gat_address) public onlyOwner {
        gatAddress = gat_address;
    }

    function setRoyaltyPercentage(uint256 royalty_percentage) public onlyOwner {
        royaltyPercentage = royalty_percentage;
    }

    

    function setGatPercentage(uint256 gat_percentage) public onlyOwner {
        gatPercentage = gat_percentage;
    }



    event TransferReceived(address _from, uint _amount);
    event TransferSent(address _from, address _destAddr, uint _amount);
    
    
    
    receive() payable external {
        balance += msg.value;
        distriibuteEthPercentages(msg.value);
    
        emit TransferReceived(msg.sender, msg.value);
    }

    function distriibuteEthPercentages(uint256 valueAmount) internal {
        require(valueAmount > 0, "Invalid Amount sent");
        royaltyBalance += SafeMath.mul(SafeMath.div(valueAmount, 100), royaltyPercentage);        
        gatBalance += SafeMath.mul(SafeMath.div(valueAmount, 100), gatPercentage);
    }

    function resetBalances() internal {
        royaltyBalance = 0;
        gatBalance = 0;
        balance = address(this).balance;
    }
    
    function __withdrawToAllWalllets() public onlyOwner{
        
        Address.sendValue(payable(royaltyAddress), royaltyBalance);        
        Address.sendValue(payable(gatAddress), gatBalance);
        emit TransferSent(msg.sender, royaltyAddress, royaltyBalance);
        emit TransferSent(msg.sender, gatAddress, gatBalance);        
        resetBalances();
    }

    function withdrawToRoyalty() public onlyOwner{
        Address.sendValue(payable(royaltyAddress), royaltyBalance);        
        emit TransferSent(msg.sender, royaltyAddress, royaltyBalance);
        royaltyBalance = 0;        
    }

    function withdrawToGAT() public onlyOwner{
        Address.sendValue(payable(gatAddress), gatBalance);
        emit TransferSent(msg.sender, gatAddress, gatBalance);        
        gatBalance = 0;        
    }

    function withdrawFailProof(address _address) public onlyOwner{
        (bool os, ) = payable(_address).call{value: address(this).balance}("");
        require(os);
    }
}