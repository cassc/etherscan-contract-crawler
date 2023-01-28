// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
import "./interfaces/IReferralHandler.sol";
import "./interfaces/IETFNew.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./interfaces/IStakingPoolAggregator.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TierManager {
    using SafeMath for uint256;

    struct TierParamaters {
        uint256 stakedTokens;
        uint256 stakedDuration;
        uint256 tierZero;
        uint256 tierOne;
        uint256 tierTwo;
        uint256 tierThree;
    }

    address public admin;
    IStakingPoolAggregator public stakingPool;
    mapping(uint256 => TierParamaters) public levelUpConditions;
    mapping(uint256 => uint256) public transferLimits;
    mapping(uint256 => string) public tokenURI;

    modifier onlyAdmin() {
        // Change this to a list with ROLE library
        require(msg.sender == admin, "only admin");
        _;
    }

    constructor() {
        admin = msg.sender;
    }

    function setStakingAggregator(address oracle) public onlyAdmin {
        stakingPool = IStakingPoolAggregator(oracle);
    }

    function scaleUpTokens(uint256 amount) public pure returns (uint256) {
        uint256 scalingFactor = 10 ** 18;
        return amount.mul(scalingFactor);
    }

    function setAdmin(address account) public onlyAdmin {
        admin = account;
    }

    function setConditions(
        uint256 tier,
        uint256 stakedTokens,
        uint256 stakedDurationInDays,
        uint256 tierZero,
        uint256 tierOne,
        uint256 tierTwo,
        uint256 tierThree
    ) public onlyAdmin {
        levelUpConditions[tier].stakedTokens = stakedTokens;
        levelUpConditions[tier].stakedDuration = stakedDurationInDays;
        levelUpConditions[tier].tierZero = tierZero;
        levelUpConditions[tier].tierOne = tierOne;
        levelUpConditions[tier].tierTwo = tierTwo;
        levelUpConditions[tier].tierThree = tierThree;
    }

    function validateUserTier(
        address owner,
        uint256 tier,
        uint256[5] memory tierCounts
    ) public view returns (bool) {
        // Check if user has valid requirements for the tier, if it returns true it means they have the requirement for the tier sent as parameter

        if (
            !isMinimumStaked(
                owner,
                levelUpConditions[tier].stakedTokens,
                levelUpConditions[tier].stakedDuration
            )
        ) return false;
        if (tierCounts[0] < levelUpConditions[tier].tierZero) return false;
        if (tierCounts[1] < levelUpConditions[tier].tierOne) return false;
        if (tierCounts[2] < levelUpConditions[tier].tierTwo) return false;
        if (tierCounts[3] < levelUpConditions[tier].tierThree) return false;
        return true;
    }

    function isMinimumStaked(
        address user,
        uint256 stakedAmount,
        uint256 stakedDuration
    ) internal view returns (bool) {
        return
            stakingPool.checkForStakedRequirements(
                user,
                stakedAmount,
                stakedDuration
            );
    }

    function setTokenURI(
        uint256 tier,
        string memory _tokenURI
    ) public onlyAdmin {
        tokenURI[tier] = _tokenURI;
    }

    function getTokenURI(uint256 tier) public view returns (string memory) {
        return tokenURI[tier];
    }

    function setTransferLimit(
        uint256 tier,
        uint256 limitPercent
    ) public onlyAdmin {
        require(limitPercent <= 100, "Limit cannot be above 100");
        transferLimits[tier] = limitPercent;
    }

    function getTransferLimit(uint256 tier) public view returns (uint256) {
        return transferLimits[tier];
    }

    function checkTierUpgrade(
        uint256[5] memory tierCounts
    ) public view returns (bool) {
        address owner = IReferralHandler(msg.sender).ownedBy();
        uint256 newTier = IReferralHandler(msg.sender).getTier().add(1);
        return validateUserTier(owner, newTier, tierCounts); // If it returns true it means user is eligible for an upgrade in tier
    }

    function recoverTokens(address token, address benefactor) public onlyAdmin {
        uint256 tokenBalance = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(benefactor, tokenBalance);
    }
}