pragma solidity ^0.6.0;

import '../interfaces/IVault.sol';
import '../Contribute.sol';
import '../Genesis.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@nomiclabs/buidler/console.sol';

contract GenesisMock is Genesis {
  constructor(
    address _reserve,
    address _contribute,
    uint256 _endTime
  ) public Genesis(_reserve, _contribute, _endTime) {}

  function setEndTime(uint256 unixTime) external {
    endTime = unixTime;
  }
}

contract ContributeMock is Contribute, Ownable {
  constructor(address _vault, uint256 _endTime) public Contribute(_vault, _endTime) {}

  function generateGenesisMock(uint256 unixTime) external {
    genesis = new GenesisMock(reserve, address(this), unixTime);
  }

  function withdraw() external onlyOwner() {
    IVault(vault).redeem(IVault(vault).getBalance());
  }

  function finishMintEvent() external {
    GME = false;
  }

  function getTime() external view returns (uint256) {
    return now;
  }

  function tokenBalance(address user) external view returns (uint256) {
    return token.balanceOf(user);
  }

  function floor() external view returns (uint256) {
    return getBurnedTokensAmount().div(DIVIDER);
  }
}