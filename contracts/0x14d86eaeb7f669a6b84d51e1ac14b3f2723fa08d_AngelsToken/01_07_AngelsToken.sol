// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import "./lib/ERC20Burnable.sol";
import "./lib/math/SafeMath.sol";
import "./lib/utils/Ownable.sol";

/**
 * @dev {ERC20} token, including:
 *
 *  - Preminted initial supply
 *  - Ability for holders to burn (destroy) their tokens
 *  - No access control mechanism (for minting/pausing) and hence no governance
 *
 * This contract uses {ERC20Burnable} to include burn capabilities - head to
 * its documentation for details.
 *
 * _Available since v3.4._
 */
struct TokenRelease {
  uint256 timestamp;
  uint256 amount;
}

contract AngelsToken is ERC20Burnable, Ownable {
  using SafeMath for uint256;
  /**
    * @dev Mints `initialSupply` amount of token and transfers them to `owner`.
    *
    * See {ERC20-constructor}.
    */
  uint256 constant initialSupply = 7874965825 * 1e18;
  uint256 mintStage = 0;
  TokenRelease[] mintSchedule;

  constructor(
      string memory name,
      string memory symbol,
      address releaseAddress
  ) ERC20(name, symbol) {
    _mint(releaseAddress, initialSupply);
    mintSchedule.push(TokenRelease({timestamp: 1640995201, amount: 78986742 * 1e18}));
    mintSchedule.push(TokenRelease({timestamp: 1672531201, amount: 77847862 * 1e18}));
    mintSchedule.push(TokenRelease({timestamp: 1704067201, amount: 76804959 * 1e18}));
    mintSchedule.push(TokenRelease({timestamp: 1735689601, amount: 75832072 * 1e18}));
    mintSchedule.push(TokenRelease({timestamp: 1767225601, amount: 74839277 * 1e18}));
    mintSchedule.push(TokenRelease({timestamp: 1798761601, amount: 73801579 * 1e18}));
    mintSchedule.push(TokenRelease({timestamp: 1830297601, amount: 72784979 * 1e18}));
    mintSchedule.push(TokenRelease({timestamp: 1861920001, amount: 71797398 * 1e18}));
    mintSchedule.push(TokenRelease({timestamp: 1893456001, amount: 70826707 * 1e18}));
    mintSchedule.push(TokenRelease({timestamp: 1924992001, amount: 69862089 * 1e18}));

    mintStage = 0;
  }

  function bulkTransfer(address[] calldata _to, uint256[] calldata _values) public  {
    require(_to.length == _values.length, "Mismatched input length");
    for (uint256 i=0; i < _to.length; i++) {
      transfer(_to[i], _values[i]);
    }
  }

  function bulkTransferFrom(address[] calldata _from, address[] calldata _to, uint256[] calldata _values) public {
    require(_from.length == _to.length, "Mismatched input length");
    require(_to.length == _values.length, "Mismatched input length");
    for (uint256 i=0; i < _to.length; i++) {
      transferFrom(_from[i], _to[i], _values[i]);
    }
  }

  function bulkApprove(address[] calldata _to, uint256[] calldata _values) public {
    require(_to.length == _values.length, "Mismatched input length");
    for (uint256 i=0; i < _to.length; i++) {
      approve(_to[i], _values[i]);
    }
  }
  
  function nextRelease() public view returns (uint256, uint256) {
    if (mintStage >= mintSchedule.length) {
      return (0, 0);
    }

    return (mintSchedule[mintStage].timestamp, mintSchedule[mintStage].amount);
  }

  function releaseTokens(address to_) public onlyOwner {
    require(to_ != address(0x0), "please provide a valid address");
    require(mintStage < mintSchedule.length, "all tokens have been minted");
    // solhint-disable-next-line not-rely-on-time
    require(block.timestamp >= mintSchedule[mintStage].timestamp, "current time is before release time");

    uint256 amount = mintSchedule[mintStage].amount;
    mintStage = mintStage + 1;
    _mint(to_, amount);
  }
}