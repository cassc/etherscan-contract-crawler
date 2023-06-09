// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interface/ID4APRB.sol";

contract D4APRB is Ownable, ID4APRB{
  uint256 public start_block;
  uint256 public period_block;
  constructor(uint256 _start_block, uint256 _period_block){
    start_block = _start_block;
    period_block = _period_block;
  }

  event D4APRBChangeStartBlock(uint256 old_start_block, uint256 new_start_block);
  function changeStartBlock(uint256 _start_block) public onlyOwner{
    emit D4APRBChangeStartBlock(start_block, _start_block);
    start_block = _start_block;
  }

  event D4APRBChangePeriodBlock(uint256 old_period_block, uint256 new_period_block);
  function changePeriodBlock(uint256 _period_block) public onlyOwner{
    emit D4APRBChangePeriodBlock(period_block, _period_block);
    period_block = _period_block;
  }

  function isStart() public view returns(bool){
    return block.number >=start_block;
  }

  function currentRound() public view returns(uint256){
    return (block.number - start_block)/period_block;
  }

}