// SPDX-License-Identifier: MIT
// fee fund splitter

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

import "./Ownable.sol";

contract SplitFunds is Ownable {

  using SafeERC20 for IERC20;


  address[] public team;
  uint256[] public weights;
  uint256 public constant DENOMINATOR = 10000; // denominates weights 10000 = 100%

  constructor() {
    // Add initial team members and weights
    team.push(0x922990AE7914d2B1b4013262EB7FEaF5BA682EF5);
    team.push(0xAdE9e51C9E23d64E538A7A38656B78aB6Bcc349e);
    weights.push(5000);
    weights.push(5000);
  }

  // Add team member with weight
  function addTeam(address _team, uint256 _weight) public onlyOwner {
    team.push(_team);
    weights.push(_weight);
  }
  // Adjust team member address or weight
  function adjustTeam(uint256 _index, address _team, uint256 _weight) public onlyOwner {
    require(team[_index] != address(0), "unassigned index");
    team[_index] = _team;
    weights[_index] = _weight;
  }

  function claimTeam(address[] memory tokens) public {
    uint256 bal;
    uint256 split;
    IERC20 ft;
    // cycle through tokens
    for(uint256 i=0;i<tokens.length;i++) {
      ft = IERC20(tokens[i]);
      bal = ft.balanceOf(address(this));
      // cycle through team addresses and weights
      for(uint32 n=0;n<team.length;n++) {
        if(weights[n] > 0 && team[n] != address(0)) {
          split = bal*weights[n]/DENOMINATOR;
          ft.safeTransfer(team[n], split);
        }
      }
    }
  }

  function execute(address _to, uint256 _value, bytes calldata _data) external onlyOwner returns (bool, bytes memory) {
    (bool success, bytes memory result) = _to.call{value:_value}(_data);
    return (success, result);
  }

}