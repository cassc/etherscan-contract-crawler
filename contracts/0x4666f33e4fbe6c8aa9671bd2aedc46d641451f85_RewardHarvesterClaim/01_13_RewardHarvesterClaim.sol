// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {RewardHarvester} from "./RewardHarvester.sol";
import {Errors} from "./libraries/Errors.sol";

contract RewardHarvesterClaim is Ownable2Step, ReentrancyGuard {
    uint256 public constant MAX_FEE = 100_000;

    // Harvester fee
    // Only single fee tracking for this version, but can be expanded for varying fees by token later
    uint256 public fee;
    // Harvester contract
    RewardHarvester public immutable harvester;

    //-----------------------//
    //        Events         //
    //-----------------------//
    event SetFee(uint256 fee);

    //-----------------------//
    //       Constructor     //
    //-----------------------//
    constructor(address _harvester, uint256 _fee) {
        if (_harvester == address(0)) revert Errors.InvalidAddress();

        harvester = RewardHarvester(_harvester);

        _setFee(_fee);
    }

    //-----------------------//
    //   External Functions  //
    //-----------------------//

    /**
        @notice Claim rewards based on the specified metadata
        @dev    Currently only perform direct claiming for this version
        @param  _token        address    Token to claim rewards
        @param  _account      address    Account to claim rewards
        @param  _amount       uint256    Amount of rewards to claim
        @param  _merkleProof  bytes32[]  Merkle proof of the claim
     */
    function claim(
        address _token,
        address _account,
        uint256 _amount,
        bytes32[] calldata _merkleProof
    ) external nonReentrant {
        // Receiver is currently set to the user itself for this version of claimer
        // but can be directed to the claimer first in the future for additional actions (ie. swaps, locks)
        harvester.claim(_token, _account, _amount, _merkleProof, fee, _account);
    }

    /**
        @notice Change fee
        @param  _newFee  uint256  New fee to set
     */
    function changeFee(uint256 _newFee) external onlyOwner {
        _setFee(_newFee);
    }

    //-----------------------//
    //   Internal Functions  //
    //-----------------------//
    /**
        @dev    Internal to set the fee
        @param  _newFee  uint256  Token address
     */
    function _setFee(uint256 _newFee) internal {
        if (_newFee > MAX_FEE) revert Errors.InvalidFee();

        fee = _newFee;

        emit SetFee(_newFee);
    }
}