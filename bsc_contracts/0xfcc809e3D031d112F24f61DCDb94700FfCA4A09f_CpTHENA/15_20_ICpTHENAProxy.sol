// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface ICpTHENAProxy {
    function mainTokenId() external view returns (uint256);
    function reserveTokenId() external view returns (uint256);
    function redeemTokenId() external view returns (uint256); 
    function THE() external view returns (address);
    function solidVoter() external view returns (address);
    function router() external view returns (address);
    function lpInitialized(address _lp) external view returns (bool);

    function withdrawableBalance() external view returns (uint256 wants);
    function balanceOfWantInMainVe() external view returns (uint256 wants);
    function balanceOfWantInReserveVe() external view returns (uint256 wants);

    function createMainLock(uint256 _amount, uint256 _lock_duration) external;
    function createReserveLock(uint256 _amount, uint256 _lock_duration) external;
    function vote(
        uint256 _tokenId,
        address[] calldata _tokenVote,
        uint256[] calldata _weights
    ) external;
    
    function merge(uint256 _from, uint256 _to) external;
    function increaseAmount(uint256 _tokenId, uint256 _amount) external;
    function increaseUnlockTime() external;
    function resetVote(uint256 _tokenId) external;
    function splitWithdraw(uint256 _amount) external returns (uint256);
    function claimVeEmissions() external returns (uint256);

    function setSolidVoter(address _solidVoter) external;
    function setVeDist(address _veDist) external;

    function getBribeReward(uint256 _tokenId, address _lp) external;
    function getTradingFeeReward(uint256 _tokenId, address _lp) external;
}