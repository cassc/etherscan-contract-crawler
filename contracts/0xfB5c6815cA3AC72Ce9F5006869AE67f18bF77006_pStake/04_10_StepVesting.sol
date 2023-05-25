/*
 Copyright [2019] - [2021], PERSISTENCE TECHNOLOGIES PTE. LTD. and the ERC20 contributors
 SPDX-License-Identifier: Apache-2.0
*/

pragma solidity 0.8.4;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { IPstake } from "./pStake.sol";

contract StepVesting is Initializable{

    using SafeERC20 for IPstake;

    event ReceiverChanged(address oldWallet, address newWallet);

    IPstake public token;
    uint64 public cliffTime;
    uint64 public stepDuration;
    uint256 public cliffAmount;
    uint256 public stepAmount;
    uint256 public numOfSteps;

    address public receiver;
    uint256 public claimed;

    modifier onlyReceiver {
        require(msg.sender == receiver, "access denied");
        _;
    }


    function initialize(
        IPstake _token,
        uint64 _cliffTime,
        uint64 _stepDuration,
        uint256 _cliffAmount,
        uint256 _stepAmount,
        uint256 _numOfSteps,
        address _receiver
    ) external initializer {
        require(
            address(_token) != address(0) && _receiver != address(0),
            "zero address not allowed"
        );

        require(_stepDuration != 0, "step duration can't be zero");

        token = _token;
        cliffTime = _cliffTime;
        stepDuration = _stepDuration;
        cliffAmount = _cliffAmount;
        stepAmount = _stepAmount;
        numOfSteps = _numOfSteps;
        receiver = _receiver;
        emit ReceiverChanged(address(0), _receiver);
    }

    function available() public view returns (uint256) {
        return claimable() - claimed;
    }

    function claimable() public view returns (uint256) {
        if (block.timestamp < cliffTime) {
            return 0;
        }

        uint256 passedSinceCliff = block.timestamp - cliffTime;
        uint256 stepsPassed = Math.min(
            numOfSteps,
            passedSinceCliff/stepDuration
        );
        return cliffAmount + (stepsPassed * stepAmount);
    }

    function setReceiver(address _receiver) public onlyReceiver {
        require(_receiver != address(0), "zero address not allowed");
        emit ReceiverChanged(receiver, _receiver);
        receiver = _receiver;
    }

    function claim() external onlyReceiver {
        uint256 amount = available();
        claimed = claimed + amount;
        token.safeTransfer(msg.sender, amount);
    }

    function delegate(address delegatee) external onlyReceiver {
        require(delegatee != address(0), "zero address not allowed");
        token.delegate(delegatee);
    }

}