// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;


import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20UtilityToken is IERC20 {
    function mint(address, uint256) external;
}

interface INonfungiblePositionManager is IERC721 {
    function positions(uint256 tokenId)
        external
        view
        returns (
            uint96 nonce,
            address operator,
            address token0,
            address token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );
}

interface IRainiLpv3StakingPoolv2 {

    struct GeneralRewardVars {
        uint32 lastUpdateTime;
        uint32 periodFinish;
        uint128 photonRewardPerTokenStored;
        uint128 photonRewardRate;
    }

    struct AccountRewardVars {
        uint64 lastBonus;
        uint32 lastUpdated;
        uint96 photonRewards;
        uint128 photonRewardPerTokenPaid;
    }

    struct AccountVars {
        uint128 xphotonBalance;
        uint128 unicornBalance;
    }

    function rewardRate() external view returns (uint256);
    function xphotonRewardRate() external view returns (uint256);
    function minRewardStake() external view returns (uint256);

    function maxBonus() external view returns (uint256);
    function bonusDuration() external view returns (uint256);
    function bonusRate() external view returns (uint256);

    function rainiLpNft() external view returns (INonfungiblePositionManager);
    function photonToken() external view returns (IERC20);
    function xphotonToken() external view returns (IERC20UtilityToken);
    function exchangeTokenAddress() external view returns (address);
    function rainiTokenAddress() external view returns (address);    

    function totalSupply() external view returns (uint256);
    function generalRewardVars() external view returns (GeneralRewardVars memory);

    function accountRewardVars(address) external view returns (AccountRewardVars memory);
    function accountVars(address) external view returns (AccountVars memory);
    function staked(address) external view returns (uint256);
    function getStakedPositions(address) external view returns (uint32[] memory);

    function minTickUpper() external view returns (int24);
    function maxTickLower() external view returns (int24);
    function feeRequired() external view returns (uint24);


    function setRewardRate(uint256) external;
    function setXphotonRewardRate(uint256) external;
    function setMinRewardStake(uint256) external;

    function setMaxBonus(uint256) external;
    function setBonusDuration(uint256) external;
    function setBonusRate(uint256) external;

    function setPhotonToken(address) external;

    function setGeneralRewardVars(GeneralRewardVars memory) external;

    function setAccountRewardVars(address, AccountRewardVars memory) external;
    function setAccountVars(address, AccountVars memory) external;

    function setStaked(address, uint256 _staked) external;
    function setTotalSupply(uint256 _totalSupply) external;

    function withdrawPhoton(address, uint256 _amount) external;

    function stakeLpNft(address, uint32 _tokenId) external;
    function withdrawLpNft(address, uint32 _tokenId) external;


    function setMinTickUpper(int24) external;
    function setMaxTickLower(int24) external;
    function setFeeRequired(uint24) external;


}