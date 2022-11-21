// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface WorldCupQuiz {
    function buyTicket(address _recipient, uint256 _amount, address _referrer) external payable;
}

contract WorldCupQuizWrapper is ReentrancyGuard {
    WorldCupQuiz public worldCupQuiz;

    constructor(address _worldCupQuiz) {
        worldCupQuiz = WorldCupQuiz(_worldCupQuiz);
    }

    function buyTicket(address _recipient, uint256 _amount, address _referrer) public payable nonReentrant {
        uint256 v = msg.value - 0.004 ether;
        worldCupQuiz.buyTicket{value: v}(_recipient, _amount, _referrer);
        payable(_recipient).transfer(0.004 ether);
    }
}