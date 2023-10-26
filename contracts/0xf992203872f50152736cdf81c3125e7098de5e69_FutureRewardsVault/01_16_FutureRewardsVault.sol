// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin-contracts/token/ERC721/IERC721.sol";
import "openzeppelin-contracts/security/ReentrancyGuard.sol";
import "openzeppelin-contracts/security/Pausable.sol";
import "openzeppelin-contracts/access/Ownable.sol";
import "openzeppelin-contracts/access/AccessControl.sol";

/**
 *  @title Adapter contract for rewards comming from psdnOCEAN
 *  @author miniroman
 *  @notice PsdnOcean booster contract relies on notifying about
 *  the rewards by calling queueNewRewards. In order to minimize changes
 *  this contract will server empty reponse for such call
 */
contract FutureRewardsVault is AccessControl {
    using SafeERC20 for IERC20;

    bytes32 public constant REWARDS_ROLE = keccak256("REWARDS_ROLE");
    address private vlPsdn;

    constructor(address vlPsdnAddress, address admin) {
        vlPsdn = vlPsdnAddress;
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(REWARDS_ROLE, admin);
    }

    // @todo run integration check against real booster contract
    function queueNewRewards(uint256) external {}

    function moveRewardsToLock(address[] calldata tokens, uint256[] calldata amounts) public onlyRole(REWARDS_ROLE) {
        for (uint256 i = 0; i < tokens.length; i++) {
            IERC20(tokens[i]).safeTransfer(vlPsdn, amounts[i]);
        }
    }

    function recoverERC20Token(address token) public onlyRole(DEFAULT_ADMIN_ROLE) {
        IERC20(token).safeTransfer(msg.sender, IERC20(token).balanceOf(address(this)));
    }
}