// SPDX-License-Identifier: MIT
// Version 1.0.0
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CryptoCricketToken is ERC20, ERC20Burnable, Pausable, Ownable {
    // decimals we use here is 18
    uint256 private constant million = 10**6 * 10**18;

    // tokenomics
    uint256 public constant MAX_MG_REWARDS = 5 * million;
    uint256 public constant MAX_FC_REWARDS = 5 * million;
    uint256 public constant MAX_MCG_REWARDS = 50 * million;
    uint256 public constant MAX_STAKING_REWARDS = 10 * million;
    uint256 public constant MAX_TEAM_REWARDS = 13 * million;
    uint256 public constant MAX_OTHER_REWARDS = 17 * million;

    // year wise minting schedule
    uint256 public constant MG_REWARDS_PER_YEAR = MAX_MG_REWARDS / 10;
    uint256 public constant FC_REWARDS_PER_YEAR = MAX_FC_REWARDS / 10;
    uint256 public constant MCG_REWARDS_PER_YEAR = MAX_MCG_REWARDS / 10;
    uint256 public constant STAKING_REWARDS_PER_YEAR = MAX_STAKING_REWARDS / 10;
    uint256 public constant TEAM_REWARDS_PER_YEAR = MAX_TEAM_REWARDS / 2;
    uint256 public constant OTHER_REWARDS_PER_YEAR = MAX_OTHER_REWARDS;

    uint256 private constant SECONDS_IN_YEAR = 365 * 24 * 60 * 60;

    uint256 private mintingStartTime = 0;
    uint256 private teamMintingStartTime = 0;
    uint256 private mintedMGRewards = 0;
    uint256 private mintedFCRewards = 0;
    uint256 private mintedMCGRewards = 0;
    uint256 private mintedStakingRewards = 0;
    uint256 private mintedTeamRewards = 0;
    uint256 private mintedOtherRewards = 0;

    constructor() ERC20("Crypto Cricket Token", "BALL") {}

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);
    }

    // maximum BALL tokens that will be issued
    function maximumRewards() external pure returns (uint256) {
        return
            MAX_MG_REWARDS +
            MAX_FC_REWARDS +
            MAX_MCG_REWARDS +
            MAX_STAKING_REWARDS +
            MAX_TEAM_REWARDS +
            MAX_OTHER_REWARDS;
    }

    function mintRewards(
        address to,
        uint256 amount,
        string memory rewardsType,
        uint256 startTime,
        uint256 rewardsPerYear,
        uint256 maxRewards,
        uint256 mintedRewards
    ) private {
        require(amount > 0, "Not a valid amount");
        require(startTime > 0, "Minting has not yet begun");

        uint256 currentYear = getCurrentYearOfMinting(startTime);
        uint256 maxAllowed = (rewardsPerYear *
            currentYear *
            (currentYear + 1)) / 2;

        maxAllowed = maxAllowed < maxRewards ? maxAllowed : maxRewards;
        require(
            maxAllowed >= mintedRewards + amount,
            string.concat(
                rewardsType,
                ":Exceeding the permissible limit for minting"
            )
        );
        _mint(to, amount);
    }

    function mintMGRewards(address to, uint256 amount) external onlyOwner {
        mintRewards(
            to,
            amount,
            "Mini Games Rewards",
            mintingStartTime,
            MG_REWARDS_PER_YEAR,
            MAX_MG_REWARDS,
            mintedMGRewards
        );
        mintedMGRewards += amount;
    }

    function mintFCRewards(address to, uint256 amount) external onlyOwner {
        mintRewards(
            to,
            amount,
            "Fantasy Cricket Rewards",
            mintingStartTime,
            FC_REWARDS_PER_YEAR,
            MAX_FC_REWARDS,
            mintedFCRewards
        );
        mintedFCRewards += amount;
    }

    function mintMCGRewards(address to, uint256 amount) external onlyOwner {
        mintRewards(
            to,
            amount,
            "Metaverse Cricket Game Rewards",
            mintingStartTime,
            MCG_REWARDS_PER_YEAR,
            MAX_MCG_REWARDS,
            mintedMCGRewards
        );
        mintedMCGRewards += amount;
    }

    function mintStakingRewards(address to, uint256 amount) external onlyOwner {
        mintRewards(
            to,
            amount,
            "Staking Rewards",
            mintingStartTime,
            STAKING_REWARDS_PER_YEAR,
            MAX_STAKING_REWARDS,
            mintedStakingRewards
        );
        mintedStakingRewards += amount;
    }

    function mintTeamRewards(address to, uint256 amount) external onlyOwner {
        mintRewards(
            to,
            amount,
            "Team Rewards",
            teamMintingStartTime,
            TEAM_REWARDS_PER_YEAR,
            MAX_TEAM_REWARDS,
            mintedTeamRewards
        );
        mintedTeamRewards += amount;
    }

    function mintOtherRewards(address to, uint256 amount) external onlyOwner {
        mintRewards(
            to,
            amount,
            "Other Rewards",
            mintingStartTime,
            OTHER_REWARDS_PER_YEAR,
            MAX_OTHER_REWARDS,
            mintedOtherRewards
        );
        mintedOtherRewards += amount;
    }

    function getCurrentYearOfMinting(uint256 startTime)
        internal
        view
        returns (uint256)
    {
        uint256 currenTime = block.timestamp;
        if (currenTime > startTime) {
            return ((currenTime - startTime) / SECONDS_IN_YEAR) + 1;
        } else {
            return 0;
        }
    }

    function startMinting() external onlyOwner {
        require(
            mintingStartTime == 0 && teamMintingStartTime == 0,
            "Minting has already commenced"
        );
        mintingStartTime = block.timestamp;
        teamMintingStartTime = mintingStartTime + SECONDS_IN_YEAR;
    }
}