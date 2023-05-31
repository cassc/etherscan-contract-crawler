/**
 *Submitted for verification at Etherscan.io on 2023-05-29
*/

contract MMOSplitter{
  address constant steviep = 0x47144372eb383466D18FC91DB9Cd0396Aa6c87A4;
  address constant paperWallet = 0x15beA68cbEdFF59fA28179896045Ce0Dd2e8E45d;
  uint256 constant nvcAmount = 25.4406 ether;

  receive() external payable {
    if (msg.value > nvcAmount) {
      payable(steviep).transfer(nvcAmount);
      payable(paperWallet).transfer(msg.value - nvcAmount);
    } else {
      payable(steviep).transfer(msg.value / 2);
      payable(paperWallet).transfer(msg.value / 2);
    }
  }
}