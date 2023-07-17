// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

import {IERC20} from './interfaces/IERC20.sol';
import {IVoteStrategyToken} from './interfaces/IVoteStrategyToken.sol';
import {SafeMath} from './libs/SafeMath.sol';

/**
 * @title AaveVoteStrategyToken
 * @notice Wrapper contract to allow fetching aggregated balance of AAVE and stkAAVE from an address,
 * used on the AaveProtoGovernance
 * @author Aave
 **/
contract AaveVoteStrategyToken is IVoteStrategyToken {
  using SafeMath for uint256;

  IERC20 public immutable AAVE;
  IERC20 public immutable STKAAVE;
  string internal constant NAME = 'Aave Vote Strategy (Aave Token + Staked Aave)';
  string internal constant SYMBOL = 'AAVE + stkAAVE';
  uint8 internal constant DECIMALS = 18;

  constructor(IERC20 aave, IERC20 stkAave) public {
    AAVE = aave;
    STKAAVE = stkAave;
  }

  function name() external override view returns (string memory) {
    return NAME;
  }

  function symbol() external override view returns (string memory) {
    return SYMBOL;
  }

  function decimals() external override view returns (uint8) {
    return DECIMALS;
  }

  /**
   * @dev Returns the aggregated AAVE + stkAAVE balance of `voter`
   * @param voter The address of the voter
   * @return The aggregated balance
   */
  function balanceOf(address voter) external override view returns (uint256) {
    return AAVE.balanceOf(voter).add(STKAAVE.balanceOf(voter));
  }
}