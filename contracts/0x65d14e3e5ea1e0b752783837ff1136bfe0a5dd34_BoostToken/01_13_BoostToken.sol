// SPDX-License-Identifier: MIT
pragma solidity ^0.5.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol";
import "@openzeppelin/contracts/access/roles/WhitelistAdminRole.sol";
import "./ERC20/ERC20TransferLiquidityLock.sol";
import "./ERC20/ERC20Distributable.sol";
import "./ERC20/ERC20Governance.sol";

/**
 *     ____  ____  ____  ___________
 *    / __ )/ __ \/ __ \/ ___/_  __/
 *   / __  / / / / / / /\__ \ / /
 *  / /_/ / /_/ / /_/ /___/ // /
 * /_____/\____/\____//____//_/
 */
contract BoostToken is ERC20Distributable,
ERC20Detailed("BOOST", "BOOST", 18),
    // governance must be before transfer liquidity lock
    // or delegates are not updated correctly
ERC20Governance,
WhitelistAdminRole,
ERC20TransferLiquidityLock
{
    function isFeeless(address account) public view returns (bool) {
        return _isFeeless[account];
    }

    function unlock() public onlyWhitelistAdmin {
        locked = false;
    }

    function setMinRebalanceAmount(uint256 amount_) public onlyWhitelistAdmin {
        minRebalanceAmount = amount_;
    }
}