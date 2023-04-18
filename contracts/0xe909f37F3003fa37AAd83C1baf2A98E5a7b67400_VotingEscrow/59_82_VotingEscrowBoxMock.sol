// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IVotingEscrow} from "../interfaces/IVotingEscrow.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {TransferHelper} from "light-lib/contracts/TransferHelper.sol";

contract VotingEscrowBoxMock {
    address public lt;
    address public veLT;

    constructor(address ltToken, address veLtAddress) {
        lt = ltToken;
        veLT = veLtAddress;

        TransferHelper.doApprove(lt, veLT, 2 ** 256 - 1);
    }

    function createLock(uint256 _value, uint256 _unlockTime) external {
        IVotingEscrow(veLT).createLock(_value, _unlockTime, 0, 0, "");
    }

    function increaseAmount(uint256 _value) external {
        IVotingEscrow(veLT).increaseAmount(_value, 0, 0, "");
    }

    function increaseUnlockTime(uint256 _unlockTime) external {
        IVotingEscrow(veLT).increaseUnlockTime(_unlockTime);
    }
}