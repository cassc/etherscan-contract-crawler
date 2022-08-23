// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./IHelixToken.sol";

interface IReferralRegister {
    function toMintPerBlock() external view returns (uint256);
    function helixToken() external view returns (IHelixToken);
    function stakeRewardPercent() external view returns (uint256);
    function swapRewardPercent() external view returns (uint256);
    function lastMintBlock() external view returns (uint256);
    function referrers(address _referred) external view returns (address);
    function rewards(address _referrer) external view returns (uint256);

    function initialize(
        IHelixToken _helixToken, 
        address _feeHandler,
        uint256 _stakeRewardPercent, 
        uint256 _swapRewardPercent,
        uint256 _toMintPerBlock,
        uint256 _lastMintBlock
    ) external; 

    function rewardStake(address _referred, uint256 _stakeAmount) external;
    function rewardSwap(address _referred, uint256 _swapAmount) external;
    function withdraw() external;
    function setToMintPerBlock(uint256 _toMintPerBlock) external;
    function setStakeRewardPercent(uint256 _stakeRewardPercent) external;
    function setSwapRewardPercent(uint256 _swapRewardPercent) external;
    function addReferrer(address _referrer) external;
    function removeReferrer() external;
    function update() external;
    function addRecorder(address _recorder) external returns (bool);
    function removeRecorder(address _recorder) external returns (bool);
    function setLastRewardBlock(uint256 _lastMintBlock) external;
    function pause() external;
    function unpause() external;
    function setFeeHandler(address _feeHandler) external;
    function setCollectorPercent(uint256 _collectorPercent) external;
    function getRecorder(uint256 _index) external view returns (address);
    function getRecorderLength() external view returns (uint256);
    function isRecorder(address _address) external view returns (bool);
}