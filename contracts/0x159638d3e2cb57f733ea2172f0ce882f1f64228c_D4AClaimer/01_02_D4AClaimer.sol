// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

import "./interface/ID4AProtocolClaim.sol";

contract D4AClaimer {
    ID4AProtocolClaim protocol;

    constructor(address _protocol) {
        protocol = ID4AProtocolClaim(_protocol);
    }

    function claimMultiReward(bytes32[] memory canvas, bytes32[] memory projects) public returns (uint256) {
        uint256 amount;
        if (canvas.length > 0) {
            for (uint256 i = 0; i < canvas.length; i++) {
                amount += protocol.claimCanvasReward(canvas[i]);
            }
        }
        if (projects.length > 0) {
            for (uint256 i = 0; i < projects.length; i++) {
                amount += protocol.claimProjectERC20Reward(projects[i]);
                amount += protocol.claimNftMinterReward(projects[i], msg.sender);
            }
        }
        return amount;
    }

    function claimMultiRewardWithETH(bytes32[] memory canvas, bytes32[] memory projects) public returns (uint256) {
        uint256 amount;
        if (canvas.length > 0) {
            for (uint256 i = 0; i < canvas.length; i++) {
                amount += protocol.claimCanvasRewardWithETH(canvas[i]);
            }
        }
        if (projects.length > 0) {
            for (uint256 i = 0; i < projects.length; i++) {
                amount += protocol.claimProjectERC20RewardWithETH(projects[i]);
                amount += protocol.claimNftMinterRewardWithETH(projects[i], msg.sender);
            }
        }
        return amount;
    }
}