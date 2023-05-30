// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

interface IXfitLiquidNFT {
    //function tokenURI(uint256 _tokenID) external view returns (string memory);
    function setBaseURI(string memory _newURI) external;
    function getLatestID() external view returns (uint256 counter);
    function getNFTData(uint256 _tokenID) external view returns (uint256 lpShare, uint256 vestingStart, uint256 vestingEnd);
    function getUnderlyingValue(uint256 _tokenID) external view returns (uint256 underlyingNFTValue);
    function getRedeemableTokenAmount(uint256 _tokenID) external view returns (uint256 redeemableAmount);
    function mint(address _to, uint256 _amount) external returns (bool);
    function boost(uint256 _amount, uint256 _tokenID) external returns (bool);
    function redeem(address _to, uint256 _amount, uint256 _tokenID) external returns (bool);

    // only owner
    function setOwner(address _owner) external;
    function setFeeGeneratingContract(address _feeGeneratingContract) external;
    function setVestingPeriodStart(uint256 _vestingPeriodStart) external;
    function setVestingPeriod(uint256 _vestingPeriod) external;

    event Staked(address indexed from, uint256 staked, uint256 lp, uint256 nftID);
    event Boosted(address indexed from, uint256 staked, uint256 lp, uint256 nftID);
    event Redeemed(address indexed from, uint256 amount, uint256 nftID);
    event ChangedOwner(address indexed newOwner);
}