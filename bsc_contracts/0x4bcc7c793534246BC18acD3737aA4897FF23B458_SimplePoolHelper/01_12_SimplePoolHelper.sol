// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20, ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "../interfaces/IBaseRewardPool.sol";
import "../interfaces/IMasterMagpie.sol";
import "../interfaces/IPoolHelper.sol";

/// @title Poolhelper
/// @author Magpie Team
/// @notice This contract is the pool helper for staking mWOM and MGP
contract SimplePoolHelper is Ownable {
    using SafeERC20 for IERC20;
    address public immutable masterMagpie;
    address public immutable stakeToken;

    /* ============ State Variables ============ */

    mapping(address => bool) authorized;

    /* ============ Errors ============ */

    error OnlyAuthorizedCaller();    

    /* ============ Constructor ============ */

    constructor(address _masterMagpie, address _stakeToken) {
        masterMagpie = _masterMagpie;
        stakeToken = _stakeToken;
    }

    /* ============ Modifiers ============ */

    modifier onlyAuthorized() {
        if (!authorized[msg.sender])
            revert OnlyAuthorizedCaller();
        _;
    }    

    /* ============ External Functions ============ */

    function depositFor(uint256 _amount, address _for) external onlyAuthorized {
        IERC20(stakeToken).safeTransferFrom(
            msg.sender,
            address(this),
            _amount
        );
        IERC20(stakeToken).safeApprove(masterMagpie, _amount);
        IMasterMagpie(masterMagpie).depositFor(stakeToken, _amount, _for);
    }

    /* ============ Admin Functions ============ */

    function authorize(address _for) external onlyOwner {
        authorized[_for] = true;
    }

    function unauthorize(address _for) external onlyOwner {
        authorized[_for] = false;
    }
}