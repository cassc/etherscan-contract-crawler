// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./interfaces/IReferralHandler.sol";
import "./interfaces/INFTFactory.sol";
import "./interfaces/IRebaserNew.sol";
import "./interfaces/IETFNew.sol";
import "./interfaces/ITaxManager.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";

contract Rewarder {
    using SafeMath for uint256;
    uint256 public BASE = 1e18;
    address public admin;

    constructor() {
        admin = msg.sender;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "only Admin");
        _;
    }

    function getRebaser(address factory) public view returns (IRebaser) {
        address rebaser = INFTFactory(factory).getRebaser();
        return IRebaser(rebaser);
    }

    function getTaxManager(address factory) public view returns (ITaxManager) {
        address taxManager = INFTFactory(factory).getTaxManager();
        return ITaxManager(taxManager);
    }

    function handleReward(
        uint256 claimedEpoch,
        address factory,
        address token
    ) external {
        ITaxManager taxManager = getTaxManager(factory);
        uint256 protocolTaxRate = taxManager.getProtocolTaxRate();
        uint256 taxDivisor = taxManager.getTaxBaseDivisor();
        uint256 rebaseRate = getRebaser(factory).getDeltaForPositiveEpoch(
            claimedEpoch
        );
        address handler = msg.sender;
        address owner = IReferralHandler(handler).ownedBy();
        INFTFactory(factory).updateUserEpoch(owner, claimedEpoch);
        if (rebaseRate != 0) {
            uint256 blockForRebase = getRebaser(factory)
                .getBlockForPositiveEpoch(claimedEpoch);
            uint256 balanceDuringRebase = IETF(token).getPriorBalance(
                owner,
                blockForRebase
            ); // We deal only with underlying balances
            balanceDuringRebase = balanceDuringRebase.div(1e6); // 4.0 token internally stores 1e24 not 1e18
            uint256 expectedBalance = balanceDuringRebase
                .mul(BASE.add(rebaseRate))
                .div(BASE);
            uint256 balanceToMint = expectedBalance.sub(balanceDuringRebase);
            handleSelfTax(
                handler,
                factory,
                balanceToMint,
                protocolTaxRate,
                taxDivisor
            );
            uint256 rightUpTaxRate = taxManager.getRightUpTaxRate();
            if (rightUpTaxRate != 0)
                handleRightUpTax(
                    handler,
                    factory,
                    balanceToMint,
                    rightUpTaxRate,
                    protocolTaxRate,
                    taxDivisor
                );
            rewardReferrers(
                handler,
                factory,
                balanceToMint,
                rightUpTaxRate,
                protocolTaxRate,
                taxDivisor
            );
        }
    }

    function handleSelfTax(
        address handler,
        address factory,
        uint256 balance,
        uint256 protocolTaxRate,
        uint256 divisor
    ) internal {
        address owner = IReferralHandler(handler).ownedBy();
        ITaxManager taxManager = getTaxManager(factory);
        uint256 selfTaxRate = taxManager.getSelfTaxRate();
        uint256 taxedAmountReward = balance.mul(selfTaxRate).div(divisor);
        uint256 protocolTaxed = taxedAmountReward.mul(protocolTaxRate).div(
            divisor
        );
        uint256 reward = taxedAmountReward.sub(protocolTaxed);
        IReferralHandler(handler).mintForRewarder(owner, reward);
        IReferralHandler(handler).alertFactory(reward, block.timestamp);
        IReferralHandler(handler).mintForRewarder(
            taxManager.getSelfTaxPool(),
            protocolTaxed
        );
    }

    function handleRightUpTax(
        address handler,
        address factory,
        uint256 balance,
        uint256 taxRate,
        uint256 protocolTaxRate,
        uint256 divisor
    ) internal {
        ITaxManager taxManager = getTaxManager(factory);
        uint256 taxedAmountReward = balance.mul(taxRate).div(divisor);
        uint256 protocolTaxed = taxedAmountReward.mul(protocolTaxRate).div(
            divisor
        );
        uint256 reward = taxedAmountReward.sub(protocolTaxed);
        address referrer = IReferralHandler(handler).referredBy();
        IReferralHandler(handler).mintForRewarder(referrer, reward);
        IReferralHandler(handler).mintForRewarder(
            taxManager.getRightUpTaxPool(),
            protocolTaxed
        );
    }

    function rewardReferrers(
        address handler,
        address factory,
        uint256 balanceDuringRebase,
        uint256 rightUpTaxRate,
        uint256 protocolTaxRate,
        uint256 taxDivisor
    ) internal {
        // This function mints the tokens and disperses them to referrers above
        ITaxManager taxManager = getTaxManager(factory);
        uint256 perpetualTaxRate = taxManager.getPerpetualPoolTaxRate();
        uint256 leftOverTaxRate = protocolTaxRate.sub(perpetualTaxRate); // Taxed and minted on rebase
        leftOverTaxRate = leftOverTaxRate.sub(rightUpTaxRate); // Tax and minted in function above
        address[5] memory referral; // Used to store above referrals, saving variable space
        // Block Scoping to reduce local Variables spillage
        {
            uint256 protocolMaintenanceRate = taxManager
                .getMaintenanceTaxRate();
            uint256 protocolMaintenanceAmount = balanceDuringRebase
                .mul(protocolMaintenanceRate)
                .div(taxDivisor);
            address maintenancePool = taxManager.getMaintenancePool();
            IReferralHandler(handler).mintForRewarder(
                maintenancePool,
                protocolMaintenanceAmount
            );
            leftOverTaxRate = leftOverTaxRate.sub(protocolMaintenanceRate);
        }
        referral[1] = IReferralHandler(handler).referredBy();
        if (referral[1] != address(0)) {
            // Block Scoping to reduce local Variables spillage
            {
                uint256 firstTier = IReferralHandler(referral[1]).getTier();
                uint256 firstRewardRate = taxManager.getReferralRate(
                    1,
                    firstTier
                );
                leftOverTaxRate = leftOverTaxRate.sub(firstRewardRate);
                uint256 firstReward = balanceDuringRebase
                    .mul(firstRewardRate)
                    .div(taxDivisor);
                IReferralHandler(handler).mintForRewarder(
                    referral[1],
                    firstReward
                );
            }
            referral[2] = IReferralHandler(referral[1]).referredBy();
            if (referral[2] != address(0)) {
                // Block Scoping to reduce local Variables spillage
                {
                    uint256 secondTier = IReferralHandler(referral[2])
                        .getTier();
                    uint256 secondRewardRate = taxManager.getReferralRate(
                        2,
                        secondTier
                    );
                    leftOverTaxRate = leftOverTaxRate.sub(secondRewardRate);
                    uint256 secondReward = balanceDuringRebase
                        .mul(secondRewardRate)
                        .div(taxDivisor);
                    IReferralHandler(handler).mintForRewarder(
                        referral[2],
                        secondReward
                    );
                }
                referral[3] = IReferralHandler(referral[2]).referredBy();
                if (referral[3] != address(0)) {
                    // Block Scoping to reduce local Variables spillage
                    {
                        uint256 thirdTier = IReferralHandler(referral[3])
                            .getTier();
                        uint256 thirdRewardRate = taxManager.getReferralRate(
                            3,
                            thirdTier
                        );
                        leftOverTaxRate = leftOverTaxRate.sub(thirdRewardRate);
                        uint256 thirdReward = balanceDuringRebase
                            .mul(thirdRewardRate)
                            .div(taxDivisor);
                        IReferralHandler(handler).mintForRewarder(
                            referral[3],
                            thirdReward
                        );
                    }
                    referral[4] = IReferralHandler(referral[3]).referredBy();
                    if (referral[4] != address(0)) {
                        // Block Scoping to reduce local Variables spillage
                        {
                            uint256 fourthTier = IReferralHandler(referral[4])
                                .getTier();
                            uint256 fourthRewardRate = taxManager
                                .getReferralRate(4, fourthTier);
                            leftOverTaxRate = leftOverTaxRate.sub(
                                fourthRewardRate
                            );
                            uint256 fourthReward = balanceDuringRebase
                                .mul(fourthRewardRate)
                                .div(taxDivisor);
                            IReferralHandler(handler).mintForRewarder(
                                referral[4],
                                fourthReward
                            );
                        }
                    }
                }
            }
        }
        // Reward Allocation
        {
            uint256 rewardTaxRate = taxManager.getRewardPoolRate();
            uint256 rewardPoolAmount = balanceDuringRebase
                .mul(rewardTaxRate)
                .div(taxDivisor);
            address rewardPool = taxManager.getRewardAllocationPool();
            IReferralHandler(handler).mintForRewarder(
                rewardPool,
                rewardPoolAmount
            );
            leftOverTaxRate = leftOverTaxRate.sub(rewardTaxRate);
        }
        // Dev Allocation & // Revenue Allocation
        {
            uint256 leftOverTax = balanceDuringRebase.mul(leftOverTaxRate).div(
                taxDivisor
            );
            address devPool = taxManager.getDevPool();
            address revenuePool = taxManager.getRevenuePool();
            IReferralHandler(handler).mintForRewarder(
                devPool,
                leftOverTax.div(2)
            );
            IReferralHandler(handler).mintForRewarder(
                revenuePool,
                leftOverTax.div(2)
            );
        }
    }

    function recoverTokens(
        address _token,
        address benefactor
    ) public onlyAdmin {
        uint256 tokenBalance = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transfer(benefactor, tokenBalance);
    }
}