/**
 *Submitted for verification at BscScan.com on 2023-01-04
*/

// File: Paymentsplitterfalllback.sol


pragma solidity 0.8.17;
contract paymentsplitterfallback {

   address payable [] public stakeholders;
   constructor(address payable [] memory _addresses) {

     for(uint i=0; i < _addresses.length; i++){
       stakeholders.push(_addresses[i]);
     }
  }

    fallback() payable external {
        
        uint256 amount = msg.value / stakeholders.length;

        for(uint i = 0; i < stakeholders.length; i++){
       stakeholders[i].transfer(amount);
    }
}



}