// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

interface IMining {
    function refreshReward(address user) external;
    function getReward() external;
}

interface IStakePool {
    function stake(uint256 _amount) external;
    function withdraw(uint256 _amount) external;
    function getReward() external;
}

interface IMintPool {
    function getAsset() external view returns(address);
    function depositAssetToMint(uint256 assetAmount, uint256 mintAmount) external;
    function depositedAsset(address _user) external view returns (uint256);
    // Price of stETH, scaled in 1e18
    function getAssetPrice() external returns (uint256);
    function withdraw(address onBehalfOf, uint256 amount) external;
    function mint(address onBehalfOf, uint256 amount) external;
    function burn(address onBehalfOf, uint256 amount) external;
    function checkWithdrawal(address user, uint256 amount) external view returns (uint256 withdrawal);
    function getPoolTotalCirculation() external view returns (uint256);
    function getBorrowedOf(address user) external view returns (uint256);
}

interface IConfigurator {
    function getVaultWeight(address pool) external view returns (uint256);
    function getEUSDAddress() external view returns (address);
    function refreshMintReward(address _account) external;
    function eUSDMiningIncentives() external view returns (address);
}

// eUSD mining incentive, dlp stake reward pool
interface IRewardPool {
    function stakedOf(address user) external view returns (uint256);
    function balanceOf(address user) external view returns (uint256);
    function getBoost(address _account) external view returns (uint256);
    function rewardPerToken() external view returns (uint256);
}

interface IEUSD {
    function totalSupply() external view returns (uint256);

    function getTotalShares() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function sharesOf(address _account) external view returns (uint256);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address _spender, uint256 _amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function transferShares(
        address _recipient,
        uint256 _sharesAmount
    ) external returns (uint256);

    function getSharesByMintedEUSD(
        uint256 _EUSDAmount
    ) external view returns (uint256);

    function getMintedEUSDByShares(
        uint256 _sharesAmount
    ) external view returns (uint256);

    function mint(
        address _recipient,
        uint256 _mintAmount
    ) external returns (uint256 newTotalShares);

    function burnShares(
        address _account,
        uint256 burnAmount
    ) external returns (uint256 newTotalShares);

    function burn(
        address _account,
        uint256 burnAmount
    ) external returns (uint256 newTotalShares);

    function transfer(address to, uint256 amount) external returns (bool);
}