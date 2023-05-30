// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.7.6;
pragma abicoder v2;

import {ERC20} from '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';

import {PreciseUnitMath} from './lib/PreciseUnitMath.sol';
import {SafeDecimalMath} from './lib/SafeDecimalMath.sol';
import {LowGasSafeMath as SafeMath} from './lib/LowGasSafeMath.sol';
import {Errors, _require, _revert} from './lib/BabylonErrors.sol';

/**
 * @title RariRefund
 * @author Babylon Finance
 *
 * Contract that refunds Rari users for the hack
 *
 */
contract RariRefund {
    using SafeERC20 for IERC20;
    using PreciseUnitMath for uint256;
    using SafeMath for uint256;
    using SafeDecimalMath for uint256;

    /* ============ Modifiers ============ */

    /* ============ Events ============ */

    event AmountClaimed(
        address _user,
        uint256 _timestamp,
        uint256 _daiAmount
    );

    /* ============ Constants ============ */

    address private constant SAFE = 0x97FcC2Ae862D03143b393e9fA73A32b563d57A6e;
    // Tokens
    IERC20 private constant DAI = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);

    /* ============ Immutables ============ */

    /* ============ State Variables ============ */

    mapping(address => uint256) public daiReimbursementAmount;
    mapping(address => bool) public claimed;

    uint256 public totalDai;
    bool public claimOpen;

    /* ============ Initializer ============ */

    constructor() {}

    /* ============ External Functions ============ */

    /**
     * Claims rari refund. Can only be done once per adddress
     *
     */
    function claimReimbursement() external {
        _require(claimOpen, Errors.CLAIM_OVER);
        uint256 daiAmount = daiReimbursementAmount[msg.sender];
        _require(!claimed[msg.sender] && daiAmount > 0, Errors.ALREADY_CLAIMED);
        claimed[msg.sender] = true;
        DAI.safeTransfer(msg.sender, daiAmount);
        emit AmountClaimed(msg.sender, block.timestamp, daiAmount);
    }

    /**
     * Sets the liquidation amount to split amongst all the whitelisted users.
     * @param _users Addresses of the user to reimburse
     * @param _daiAmounts Amounts of DAI to reimburse
     */
    function setUserReimbursement(
        address[] calldata _users,
        uint256[] calldata _daiAmounts
    ) external {
        require(msg.sender == SAFE ||
          (!claimOpen && msg.sender == 0x08839d766B1381014868eB0C3aa1C64db2B02326), 'Only emergency owner');
        for (uint256 i = 0; i < _users.length; i++) {
            require(!claimed[_users[i]], 'Already claimed');
            totalDai = totalDai.sub(daiReimbursementAmount[_users[i]]).add(_daiAmounts[i]);
            daiReimbursementAmount[_users[i]] = _daiAmounts[i];
        }
    }

    /**
     * Starts reimbursement process
     */
    function startRefund() external {
        require(msg.sender == SAFE, 'Only emergency owner');
        _require(
            DAI.balanceOf(address(this)) >= totalDai,
            Errors.REFUND_TOKENS_NOT_SET
        );
        claimOpen = true;
    }

    /**
     * Recover all proceeds in case of emergency
     */
    function retrieveRemaining() external {
        require(msg.sender == SAFE, 'Only emergency owner');
        DAI.safeTransfer(SAFE, DAI.balanceOf(address(this)));
    }
}