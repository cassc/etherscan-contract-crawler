pragma solidity ^0.5.17;

import "./SafeMath.sol";
import "./IERC20.sol";

contract Airdrop{
  using SafeMath for uint;
  function airdrop(address[] memory toAirdrop,uint[] memory ethFromEach,uint totalEth,uint tokensRewarded,address tokenAddress) public{
    uint totalEth2=0;
    uint totalRewards=0;
    for(uint i=0;i<toAirdrop.length;i++){
      totalEth2+=ethFromEach[i];
      uint tokensToSend=(tokensRewarded.mul(ethFromEach[i])).div(totalEth);
      totalRewards+=tokensToSend;
      ERC20(tokenAddress).transferFrom(msg.sender,toAirdrop[i],tokensToSend);

    }
    require(totalRewards<=tokensRewarded,"tokens sent must add up to nearly the total");
    require(totalRewards>tokensRewarded.sub(tokensRewarded.div(200)),"tokens sent must add up to nearly the total");
    require(totalEth2==totalEth,"inputs must add up to the total");
  }
}
