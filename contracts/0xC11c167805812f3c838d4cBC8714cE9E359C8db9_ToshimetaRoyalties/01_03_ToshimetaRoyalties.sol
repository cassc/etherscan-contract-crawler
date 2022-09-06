// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;
import "@openzeppelin/contracts/access/Ownable.sol";

contract ToshimetaRoyalties is Ownable {
  address addr1 = 0xdC7dBFd6ab4BF3215b01806ae9edDC7447016793;
  address addr2 = 0xB9aC442e606809459d7E80C75c5eaBE5eaC3b88b;
  address addr3 = 0x0cAd323FB84Eb9D7BA2e42Cb4Afaf09157D72A16;
  address addr4 = 0x6352E129FdD4acCd2B1DE6B7bb13142800Ad6CE1;
  address addr5 = 0xB9b2dF03F48d86F9d02c00FB56DaDb42962d784D;

  
  function withdraw() public onlyOwner {
      uint256 balance = address(this).balance;
      require(balance > 0, "contract balance is 0");
      payable(addr1).transfer((balance * 200) / 1000);
      payable(addr2).transfer((balance * 200) / 1000);
      payable(addr3).transfer((balance * 200) / 1000);
      payable(addr4).transfer((balance * 200) / 1000);
      payable(addr5).transfer((balance * 200) / 1000);
  }
}