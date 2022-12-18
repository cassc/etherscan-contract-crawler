// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./WarpStakingV2.sol";
import "./WarpStakingV2Mothership.sol";
import "./pancake/interfaces/IPancakePair.sol";

contract WarpStakingV2ChildCreator is AccessControl {
    bytes32 public constant MOTHER_ROLE = keccak256("MOTHER_ROLE");

    constructor(address admin_) {
        _setupRole(DEFAULT_ADMIN_ROLE, admin_);
        _setupRole(MOTHER_ROLE, admin_);
    }

    function newWarpStaking(
        IERC20 token_,
        IERC20 rewardToken_,
        IPancakePair lp_,
        string memory name_,
        string memory symbol_,
        uint256 apr_,
        uint256 period_,
        bytes memory data
    ) public onlyRole(MOTHER_ROLE) returns (WarpStakingV2) {
        return
            new WarpStakingV2(
                WarpStakingV2Mothership(msg.sender),
                token_,
                rewardToken_,
                lp_,
                name_,
                symbol_,
                apr_,
                period_
            );
    }
}