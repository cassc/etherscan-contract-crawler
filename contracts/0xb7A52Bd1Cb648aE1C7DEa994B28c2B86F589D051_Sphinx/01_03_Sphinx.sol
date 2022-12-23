// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";

// User submits answers 3 riddles, first person to get them all right wins.
// The winners will share 69% of the pool according to the proportion they staked.
contract Sphinx is Ownable {

  bytes32 private solution;
  uint private minimum = 0.025 ether;
  uint private maximum = 1.0 ether;
  bool private gameClosed = false;
  uint public numEntries = 0;
  uint public timestamp;
  address public winner;

  event Fail(string message);
  event Receipt(string message);

  mapping(address => uint) public participants;

  //deploy with solutions, set 1 day time limit [16 hours for testing]
  constructor(bytes32 _solution) {
      solution = _solution;
      timestamp = block.timestamp + 87000;
  }

  modifier callerIsUser() {
    require(tx.origin == msg.sender, "The caller is another contract");
    _;
  }

  // Accept 3 guesses + compare to solutions
  function entry(string memory answer) external payable callerIsUser {

    require (
      block.timestamp < timestamp, 
      "the game has closed"
    );

    require(
      msg.value >= minimum,
      "entry cost too low"
    );

    require(
      msg.value <= maximum,
      "entry cost too high"
    );

    if (bytes(answer).length > 0) {
      numEntries++;
      emit Receipt("Confirmed");
    }else{
      emit Fail("Error");
    }
  }

  function reveal(
    string memory answerA, 
    string memory answerB, 
    string memory answerC, 
    string memory secretSalt) external view onlyOwner returns (bytes32) {
      string memory revealedSolution = string.concat(answerA, answerB, answerC,secretSalt);
      bytes32 testHash = sha256(abi.encodePacked((revealedSolution)));
      return testHash;
  }

  function getNumEntries() public view returns (uint) {
    return numEntries;
  }

  function getContractBalance() public view onlyOwner returns (uint) {
    return address(this).balance;
  }

  // Withdraw entire balance
  function withdrawAll() external onlyOwner {
    payable(msg.sender).transfer(address(this).balance);
  }

  // For testing
  function manualGameOpen() external onlyOwner {
    gameClosed = false;
  }
}