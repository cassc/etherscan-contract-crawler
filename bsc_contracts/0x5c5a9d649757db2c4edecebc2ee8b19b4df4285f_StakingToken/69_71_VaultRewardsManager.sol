// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.4;

import "./IStakingToken.sol";
import "./IStakingVault.sol";

import "./Whitelist.sol";
import "./TokensRecoverable.sol";

contract VaultRewardsManager is Whitelist, TokensRecoverable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address;

    IERC20 public token;
    IStakingToken public stake;

    mapping (IERC20 => address[]) internal vaults_;
    mapping (IERC20 => uint256[]) internal rates_;

    event RewardsDistributed(address indexed token, uint256 amount);

    constructor(address _token, address _stake) {
        token = IERC20(_token);
        stake = IStakingToken(_stake);
    }

    ////////////////////
    // VIEW FUNCTIONS //
    ////////////////////

    function getVaults(address _token) external view returns (address[] memory) {
        return vaults_[IERC20(_token)];
    }

    function getRates(address _token) external view returns (uint256[] memory) {
        return rates_[IERC20(_token)];
    }

    //////////////////////
    // PUBLIC FUNCTIONS //
    //////////////////////

    function prepareRewards() external returns (bool success) {
        uint256 amount = token.balanceOf(address(this));
        require(amount > 0, "Nothing to prepare");

        token.approve(address(stake), type(uint256).max);
        
        success = stake.stake(amount);
        require(success, "Stake failed");
    }

    //////////////////////////
    // RESTRICTED FUNCTIONS //
    //////////////////////////

    function distribute() external onlyWhitelisted() returns (bool success) {
        uint256 availableRewards = token.balanceOf(address(this));
        require (availableRewards > 0, "Nothing to pay");

        address[] memory vaults = vaults_[token];
        uint256[] memory rates = rates_[token];

        for (uint256 i = 0; i < vaults.length; i++) {
            address vault = vaults[i];
            uint256 rate = rates[i];

            if (rate > 0) {
                uint256 feeAmount = rate * availableRewards / 10000;
                IStakingVault(vault).addToRewards(feeAmount);
            }
        }

        emit RewardsDistributed(address(token), availableRewards);
        return true;
    }

    //////////////////////////
    // OWNER-ONLY FUNCTIONS //
    //////////////////////////

    function setToken(address _tokenAddress) public ownerOnly() {
        token = IERC20(_tokenAddress);
    }

    function setStake(address _stakeAddress) public ownerOnly() {
        stake = IStakingToken(_stakeAddress);
    }

    function setDistributionRates(address[] memory vaults, uint256[] memory rates) public ownerOnly() {
        
        uint256 points = 0;

        for (uint256 i = 0; i < rates.length; i++) {
            points = points + rates[i];
        }

        require (points == 10000, "Total fee rate must be 100%");

        for (uint256 i = 0; i < vaults.length; i++) {
            require (IERC20(address(stake)).approve(vaults[i], type(uint256).max), "Invalid token");
        }

        vaults_[token] = vaults;
        rates_[token] = rates;
    }
}