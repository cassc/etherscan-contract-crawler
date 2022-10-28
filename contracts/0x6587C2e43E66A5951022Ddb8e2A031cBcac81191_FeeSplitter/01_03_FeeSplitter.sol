//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IERC20 {
  function balanceOf(address account) external view returns (uint256);
  function transfer(address _to, uint256 _amount) external returns (bool);
}

contract FeeSplitter is Ownable {
  event Received(address, uint);

  address public communityFundAddress = address(0);
  address public teamFundAddress = address(0);

  uint256 public communityFundRateMultiplier = 1;
  uint256 public communityFundRateDivider = 2;

  uint256 public totalFeeReceived = 0;
  uint256 public totalCommunityFundFeeReceived = 0;
  uint256 public totalTeamFundReceived = 0;

  constructor() {
  }

  function setCommunityFundAddress(address addr) public onlyOwner {
    communityFundAddress = addr;
  }

  function setTeamFundAddress(address addr) public onlyOwner {
    teamFundAddress = addr;
  }

  function setCommunityFundRateMultiplier(uint256 multiplier) public onlyOwner {
    communityFundRateMultiplier = multiplier;
  }

  function setCommunityFundRateDivider(uint256 divider) public onlyOwner {
    communityFundRateDivider = divider;
  }

  ////////////////////////////////////////////////////
  // Withdrawal, in case if there is something wrong
  ////////////////////////////////////////////////////

  function withdraw() public onlyOwner {
    uint256 balance = address(this).balance;
    payable(msg.sender).transfer(balance);
  }

  function withdrawToken(address tokenAddress) public onlyOwner {
    IERC20 tokenContract = IERC20(tokenAddress);
    tokenContract.transfer(msg.sender, tokenContract.balanceOf(address(this)));
  }

  /////////////
  // Fallback
  /////////////

  receive() external payable {
    require(communityFundAddress != address(0), "Community fund address is not yet set");
    require(teamFundAddress != address(0), "Team fund address is not yet set");

    uint256 to_public_goods = msg.value * communityFundRateMultiplier / communityFundRateDivider;
    uint256 to_team = msg.value - to_public_goods;

    payable(communityFundAddress).transfer(to_public_goods);
    payable(teamFundAddress).transfer(to_team);

    totalFeeReceived = totalFeeReceived + msg.value;
    totalCommunityFundFeeReceived = totalCommunityFundFeeReceived + to_public_goods;
    totalTeamFundReceived = totalTeamFundReceived + to_team;

    emit Received(msg.sender, msg.value);
  }
}