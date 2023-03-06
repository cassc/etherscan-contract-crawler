// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

contract DVESale is OwnableUpgradeable, PausableUpgradeable {
    mapping(address => uint256) public dividend;

    uint256 public amountPurchsed;

    mapping(address => address[]) public previousReferrals;
    mapping(address => mapping(address => bool)) public previousReferralsCheck;

    IERC20 public DVE;
    IERC20 public BUSD; // 0xe9e7cea3dedca5984780bafc599bd69add087d56

    event BuyTokens(address buyer, uint256 amountOfTokens);
    event ReferralTokens(address ref, uint256 amount);

    function initialize(address _DVEAddress, address _BUSDAddress)
        public
        initializer
    {
        __Ownable_init();
        __Pausable_init();

        require(_DVEAddress != address(0), "DVE address cannot be 0x0");
        require(_BUSDAddress != address(0), "BUSD address cannot be 0x0");

        DVE = IERC20(_DVEAddress);
        BUSD = IERC20(_BUSDAddress);
    }

    // ********** USER FUNCTIONS **********

    function buyTokens(address ref, uint256 amount) external whenNotPaused {
        require(ref != msg.sender, "Cannot refer yourself");

        require(amount > 0, "Must purchase a positive number of tokens");
        require(
            amount < DVE.balanceOf(address(this)),
            "There are not enough tokens left to purchase"
        );

        bool paymentSuccessful = BUSD.transferFrom(
            msg.sender,
            address(this),
            amount
        );
        require(paymentSuccessful, "Payment was not successful");

        bool success = DVE.transfer(msg.sender, amount);
        require(success, "Sending failed");

        if (ref != address(0)) {
            giveReferrals(ref, amount);
        }

        amountPurchsed = amountPurchsed + amount;

        emit BuyTokens(msg.sender, amount);
    }

    // ********** UTILITY FUNCTIONS **********

    function giveReferrals(address l1Ref, uint256 amount) internal {
        // 1. Record the referral
        // 2. Give the level one referral 10% of the amount
        // 3. Give the level two referral (those who the level one referral got referrals from) 5% of the amount
        // 4. Give the level three referral (those who the level two referral got referrals from) 2.5% of the amount

        uint256 total = 0;

        uint256 l1Amount = amount / 10; // 10%
        uint256 l2Amount = amount / 20; // 5%
        uint256 l3Amount = amount / 40; // 2.5%

        if (!previousReferralsCheck[msg.sender][l1Ref]) {
            previousReferrals[msg.sender].push(l1Ref);
            previousReferralsCheck[msg.sender][l1Ref] = true;
        }

        bool successL1 = DVE.transfer(l1Ref, l1Amount);
        require(successL1, "Sending to ref failed");

        total += l1Amount;

        address[] memory l2Refs = previousReferrals[l1Ref];
        for (uint256 i = 0; i < l2Refs.length; i++) {
            address l2Ref = l2Refs[i];

            bool successL2 = DVE.transfer(l2Ref, l2Amount);
            require(successL2, "Sending to ref failed");

            total += l2Amount;

            address[] memory l3Refs = previousReferrals[l2Ref];
            for (uint256 j = 0; j < l3Refs.length; j++) {
                address l3Ref = l3Refs[j];

                bool successL3 = DVE.transfer(l3Ref, l3Amount);
                require(successL3, "Sending to ref failed");

                total += l3Amount;

                // Safety check to prevent gas limit issues
                if (j >= 10) {
                    break;
                }
            }

            // Safety check to prevent gas limit issues
            if (i >= 10) {
                break;
            }
        }

        // We avoid sending an event for each referral, and instead send one event for all referrals
        // We want to save gas, and Transfer events are already emitted for each transaction in this function
        emit ReferralTokens(msg.sender, total);
    }

    // ********** OWNER FUNCTIONS **********

    function withdraw(address target) external onlyOwner whenNotPaused {
        bool success = BUSD.transfer(target, BUSD.balanceOf(address(this)));
        require(success, "Withdraw transfer failed");
    }

    function setBUSDAddress(address _BUSDAddress) external onlyOwner {
        require(_BUSDAddress != address(0), "BUSD address cannot be 0x0");
        BUSD = IERC20(_BUSDAddress);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}