// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IBlxPresale {

    function presaleSoftCapStatus() external view returns(bool);
    function presaleClosed() external view returns(bool);
    function rewardBurnt() external view returns(bool);
    function updateReferrer(address user, address referrer, uint amount, uint blx) external;
    function claimRewards(address referrer) external returns (uint blx, uint rewards);
    function burnRemainingBLX() external;
    function purchase(uint amount, address referrer, address sender, bool collectFee) external;
    function refund(address msgSender) external returns (uint amount, bool alreadyRedeemed);
    function blxObligation() external view returns (uint amount);
    function daoAgentAddress() external view returns (address daoAgentAddress);
}