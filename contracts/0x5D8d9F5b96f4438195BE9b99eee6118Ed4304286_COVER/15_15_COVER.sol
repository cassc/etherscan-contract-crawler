// SPDX-License-Identifier: None

pragma solidity ^0.7.4;

import "./utils/SafeMath.sol";
import "./utils/Ownable.sol";
import "./ERC20/ERC20.sol";

/**
 * @title COVER token contract
 * @author [email protected]
 */
contract COVER is Ownable, ERC20 {
  using SafeMath for uint256;

  bool private isReleased;
  address public blacksmith; // mining contract
  address public migrator; // migration contract
  uint256 public constant START_TIME = 1605830400; // 11/20/2020 12am UTC

  constructor () ERC20("Cover Protocol", "COVER") {
    // mint 1 token to create pool2
    _mint(0x2f80E5163A7A774038753593010173322eA6f9fe, 1e18);
  }

  function mint(address _account, uint256 _amount) public {
    require(isReleased, "$COVER: not released");
    require(msg.sender == migrator || msg.sender == blacksmith, "$COVER: caller not migrator or Blacksmith");

    _mint(_account, _amount);
  }

  function setBlacksmith(address _newBlacksmith) external returns (bool) {
    require(msg.sender == blacksmith, "$COVER: caller not blacksmith");

    blacksmith = _newBlacksmith;
    return true;
  }

  function setMigrator(address _newMigrator) external returns (bool) {
    require(msg.sender == migrator, "$COVER: caller not migrator");

    migrator = _newMigrator;
    return true;
  }

  /// @notice called once and only by owner
  function release(address _treasury, address _vestor, address _blacksmith, address _migrator) external onlyOwner {
    require(block.timestamp >= START_TIME, "$COVER: not started");
    require(isReleased == false, "$COVER: already released");

    isReleased = true;

    blacksmith = _blacksmith;
    migrator = _migrator;
    _mint(_treasury, 950e18);
    _mint(_vestor, 10800e18);
  }
}