// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./IHelixNFT.sol";
import "./IHelixToken.sol";

interface IHelixChefNFT {
    function helixNFT() external view returns (IHelixNFT helixNFT);
    function helixToken() external view returns (IHelixToken helixToken);
    function initialize(address _helixNFT, address _helixToken, address feeMinter) external;
    function stake(uint256[] memory _tokenIds) external;
    function unstake(uint256[] memory _tokenIds) external;
    function accrueReward(address _user, uint256 _fee) external;
    function withdrawRewardToken() external;
    function addAccruer(address _address) external;
    function removeAccruer(address _address) external;
    function pause() external;
    function unpause() external;
    function getAccruer(uint256 _index) external view returns (address accruer);
    function getUsersStakedWrappedNfts(address _user) external view returns(uint256 numStakedNfts);
    function pendingReward(address _user) external view returns (uint256 pendingReward);
    function getNumAccruers() external view returns (uint256 numAccruers);
    function getAccruedReward(address _user, uint256 _fee) external view returns (uint256 reward);
    function isAccruer(address _address) external view returns (bool);
    function users(address _user) external view returns (
        uint256[] memory stakedNFTsId, 
        uint256 accruedReward,
        uint256 rewardDebt,
        uint256 stakedNfts
    );
    function getUserStakedNfts(address _user) external view returns (uint256);
}