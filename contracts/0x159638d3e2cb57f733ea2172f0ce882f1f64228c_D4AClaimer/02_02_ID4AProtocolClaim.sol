// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

interface ID4AProtocolClaim {
    function claimProjectERC20Reward(bytes32 _project_id) external returns (uint256);
    function claimProjectERC20RewardWithETH(bytes32 _project_id) external returns (uint256);
    function claimCanvasReward(bytes32 _canvas_id) external returns (uint256);
    function claimCanvasRewardWithETH(bytes32 _canvas_id) external returns (uint256);
    function claimNftMinterReward(bytes32 _project_id, address _minter) external returns (uint256);
    function claimNftMinterRewardWithETH(bytes32 _project_id, address _minter) external returns (uint256);
}