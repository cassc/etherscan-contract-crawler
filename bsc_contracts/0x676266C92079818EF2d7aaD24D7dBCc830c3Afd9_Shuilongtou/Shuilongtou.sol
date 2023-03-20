/**
 *Submitted for verification at BscScan.com on 2023-03-19
*/

pragma solidity ^0.8.10;
contract Shuilongtou {
    function withdraw(uint amount) public {
        //合约调用者的地址 msg.sender()
        require(amount <= 10 * 10 ** 18);
        payable(msg.sender).transfer(amount);
    }
}