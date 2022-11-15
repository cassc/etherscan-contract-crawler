// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.17;

import { Ownable } from 'openzeppelin-contracts/access/Ownable.sol';

// import { IHedgerWhitelist } from '../interfaces/IHedgerWhitelist.sol';
import { HedgerWhitelist } from '../HedgerWhitelist.sol';

/*

  NOTE: All functions here should be marked internal!

*/
contract BaseHedger {
  // uint256 internal maxSlippage = 10000; // 10^4 or 1% // 100 is 0.01%

  uint256 internal LTV = 0.65e4; // 6500 => 65%

  HedgerWhitelist internal whitelist;

  constructor(address _whitelist) {
    whitelist = HedgerWhitelist(_whitelist);
  }

  // function depositSynapse() internal {
    
  // }

  // function withdrawSynapse() internal {

  // }

  // function setMaxSlippage(uint16 s) public onlyOwner {
  //   maxSlippage = s;
  // }

  /// @dev Amount - amount * slippage
  /// @param a Amount of token
  /// @param s Desired slippage in 10^4 (e.g. 0.01% => 0.01e4 => 100)
  function _amountLessSlippage(uint256 a, uint256 s) internal pure returns (uint256) {
    return (a * (10 ** 6 - s)) / 10 ** 6;
  }

  /// @dev Amount + amount * slippage
  /// @param a Amount of token
  /// @param s Desired slippage in 10^4 (e.g. 0.01% => 0.01e4 => 100)
  function _amountMoreSlippage(uint256 a, uint256 s) internal pure returns (uint256) {
    // slippage: 0.5e4 (0.5%)
    return (a * (10 ** 6 + s)) / 10 ** 6;
  }

  fallback() external payable {}
	receive() external payable {}
}