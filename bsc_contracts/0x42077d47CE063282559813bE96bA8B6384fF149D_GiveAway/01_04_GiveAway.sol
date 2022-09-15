// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/**
 * @dev auction give away
 */
contract GiveAway is Ownable {
    mapping(address => uint) public finished;
    
    receive() external payable {}

    function withdraw() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function giveAway(address[] memory addrs, uint[] memory amount) public onlyOwner {
        for (uint i = 0; i < addrs.length; i++) {
            require(finished[addrs[i]] == 0, "GiveAway: already finished");
            if (finished[addrs[i]] != 1) {
                payable(addrs[i]).transfer(amount[i]);
                finished[addrs[i]] = 1;
            }
        }
    }
}