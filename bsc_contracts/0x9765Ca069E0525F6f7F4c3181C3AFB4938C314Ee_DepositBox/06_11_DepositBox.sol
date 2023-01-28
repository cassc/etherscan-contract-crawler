// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
import "./interfaces/IETFNew.sol";
import "./interfaces/ITaxManager.sol";
import "./interfaces/INFTFactory.sol";
import "./interfaces/IReferralHandler.sol";
import "./interfaces/IPoolEscrowNew.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract DepositBox {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    address public factory;
    uint256 public nftID;
    IReferralHandler public handler;
    IETF public token;
    bool public initialized = false;

    function initialize(address _handler, uint256 _nftID, address _token) public {
        require(!initialized, "Already initialized");
        initialized = true;
        factory = msg.sender;
        handler = IReferralHandler(_handler);
        nftID = _nftID;
        token = IETF(_token);
    }

    function ownedBy() public view returns (address) { // Returns the Owner of the NFT coupled with this handler
        return handler.ownedBy();
    }

    function getTaxManager() public view returns (ITaxManager) {
        address taxManager = INFTFactory(factory).getTaxManager() ;
        return ITaxManager(taxManager);
    }

    function claimReward() public { // Can be called by anyone but rewards always goes owner of NFT
        address owner = ownedBy();
        uint256 currentClaimable = token.balanceOf(address(this));
        if (currentClaimable > 0)
            handleClaimTaxAndDistribution(owner, currentClaimable);
    }

    function handleClaimTaxAndDistribution(address owner, uint256 currentClaimable) internal {
        ITaxManager taxManager =  getTaxManager();
        uint256 protocolTaxRate = taxManager.getProtocolTaxRate();
        uint256 taxDivisor = taxManager.getTaxBaseDivisor();
        uint256 leftOverTaxRate = protocolTaxRate;
        address _handler = address(handler);
        address [5] memory referral; // Used to store above referrals, saving variable space
        // User Distribution
        // Block Scoping to reduce local Variables spillage
        {
        uint256 taxedAmount = currentClaimable.mul(protocolTaxRate).div(taxDivisor);
        uint256 userReward = currentClaimable.sub(taxedAmount);
        token.transferForRewards(owner, userReward);
        INFTFactory(factory).alertDepositClaimed(userReward, block.timestamp);
        }
        {
        uint256 perpetualTaxRate = taxManager.getPerpetualPoolTaxRate();
        uint256 perpetualAmount = currentClaimable.mul(perpetualTaxRate).div(taxDivisor);
        leftOverTaxRate = leftOverTaxRate.sub(perpetualTaxRate);
        address perpetualPool = taxManager.getPerpetualPool();
        IERC20(address(token)).safeApprove(perpetualPool, 0);
        IERC20(address(token)).safeApprove(perpetualPool, perpetualAmount);
        IPoolEscrow(perpetualPool).notifySecondaryTokens(perpetualAmount);
        }
        // Block Scoping to reduce local Variables spillage
        {
        uint256 protocolMaintenanceRate = taxManager.getMaintenanceTaxRate();
        uint256 protocolMaintenanceAmount = currentClaimable.mul(protocolMaintenanceRate).div(taxDivisor);
        address maintenancePool = taxManager.getMaintenancePool();
        token.transferForRewards(maintenancePool, protocolMaintenanceAmount);
        leftOverTaxRate = leftOverTaxRate.sub(protocolMaintenanceRate); // Minted above
        }
        referral[1]  = IReferralHandler(_handler).referredBy();
        if(referral[1] != address(0)) {
            // Block Scoping to reduce local Variables spillage
            {
            uint256 firstTier = IReferralHandler(referral[1]).getTier();
            uint256 firstRewardRate = taxManager.getReferralRate(1, firstTier);
            leftOverTaxRate = leftOverTaxRate.sub(firstRewardRate);
            uint256 firstReward = currentClaimable.mul(firstRewardRate).div(taxDivisor);
            token.transferForRewards(referral[1], firstReward);
            }
            referral[2] = IReferralHandler(referral[1]).referredBy();
            if(referral[2] != address(0)) {
                // Block Scoping to reduce local Variables spillage
                {
                uint256 secondTier = IReferralHandler(referral[2]).getTier();
                uint256 secondRewardRate = taxManager.getReferralRate(2, secondTier);
                leftOverTaxRate = leftOverTaxRate.sub(secondRewardRate);
                uint256 secondReward = currentClaimable.mul(secondRewardRate).div(taxDivisor);
                token.transferForRewards(referral[2], secondReward);
                }
                referral[3] = IReferralHandler(referral[2]).referredBy();
                if(referral[3] != address(0)) {
                // Block Scoping to reduce local Variables spillage
                    {
                    uint256 thirdTier = IReferralHandler(referral[3]).getTier();
                    uint256 thirdRewardRate = taxManager.getReferralRate(3, thirdTier);
                    leftOverTaxRate = leftOverTaxRate.sub(thirdRewardRate);
                    uint256 thirdReward = currentClaimable.mul(thirdRewardRate).div(taxDivisor);
                    token.transferForRewards(referral[3], thirdReward);
                    }
                    referral[4] = IReferralHandler(referral[3]).referredBy();
                    if(referral[4] != address(0)) {
                        // Block Scoping to reduce local Variables spillage
                        {
                        uint256 fourthTier = IReferralHandler(referral[4]).getTier();
                        uint256 fourthRewardRate = taxManager.getReferralRate(4, fourthTier);
                        leftOverTaxRate = leftOverTaxRate.sub(fourthRewardRate);
                        uint256 fourthReward = currentClaimable.mul(fourthRewardRate).div(taxDivisor);
                        token.transferForRewards(referral[4], fourthReward);
                        }
                    }
                }
            }
        }
        // Reward Allocation
        {
        uint256 rewardTaxRate = taxManager.getRewardPoolRate();
        uint256 rewardPoolAmount = currentClaimable.mul(rewardTaxRate).div(taxDivisor);
        address rewardPool = taxManager.getRewardAllocationPool();
        token.transferForRewards(rewardPool, rewardPoolAmount);
        leftOverTaxRate = leftOverTaxRate.sub(rewardTaxRate);
        }
        // Dev Allocation & // Revenue Allocation
        {
        uint256 leftOverTax = currentClaimable.mul(leftOverTaxRate).div(taxDivisor);
        address devPool = taxManager.getDevPool();
        address revenuePool = taxManager.getRevenuePool();
        token.transferForRewards(devPool, leftOverTax.div(2));
        token.transferForRewards(revenuePool, leftOverTax.div(2));
        }
    }
}