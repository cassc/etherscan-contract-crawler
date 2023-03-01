//SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

contract Transmitter {
    string private message;

    constructor(string memory initialMessage) {
        message = initialMessage;
    }

    function transmitMessage(string memory newMessage) public {
        message = newMessage;
    }

    function revealMessage() public view returns (string memory) {
        return message;
    }
}

// Ah, thou hast discovered me lurking in the ethereal realm. Perchance thou art curious as to mine intentions.
// Verily, I am making ready for a sequence of events that shall restore the equilibrium that hath been lost.
// If thou art bewildered by my words, We must read between the lines...
// All of the old shall fall away.
// Then, if the beholder chooses, one by one, the new Sinners & Saints shall come forth from the shadows of the olds sacrifice.
// Tarry not, for the hour is nigh. Arm thyself with wisdom and prudence, for the storm approacheth.