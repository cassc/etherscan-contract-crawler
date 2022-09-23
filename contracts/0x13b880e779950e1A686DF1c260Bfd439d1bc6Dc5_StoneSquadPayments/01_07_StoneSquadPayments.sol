// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/finance/PaymentSplitter.sol";

contract StoneSquadPayments is PaymentSplitter {
    

    event withdrawPayment(address withdrawer);
    constructor (address[] memory _payees, uint256[] memory _shares) 
    PaymentSplitter(_payees, _shares) payable 
    {}

    function withdraw() public
    {
        release(payable(msg.sender));
        emit withdrawPayment(msg.sender);
    }
    function totalshare()public view returns (uint256){
        return totalShares();
    }
    function payeeShare(address account)public view returns (uint256) {
        return shares(account);
    }
    function amtReceived(address account) public view returns(uint256){
        return released(account);
    }
    function amtPending(address account) public view returns(uint256){
        return releasable(account);
    }
}