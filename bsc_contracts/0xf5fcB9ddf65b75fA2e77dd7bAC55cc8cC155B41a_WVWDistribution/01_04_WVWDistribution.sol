// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
    This contracts will gona control all token supply of WVW, and it guarantees that anything will going to be different from WVW Tokenomics.
    Onwer can't even change wallets if he wants to.
    Claims are gonna be locked until it gets the timeslock from each tokenomic rules.
 */
contract WVWDistribution is Ownable {
    IERC20 private token;
    uint256 private startDateDistribution;
    bool private tokenConfigured;

    uint256 private constant oneDay = 1 days;
    uint256 private constant oneMonth = 30 days;
    uint256 private constant sixMonths = 180 days;

    address private walletTeam;
    address private walletPartners;
    address private walletGiveways;
    address private walletLiquidityExchange;
    address private walletLaunch;
    address private walletStake;
    address private walletFounder;

    struct DistributionItem {
        address wallet;
        uint256 lastClaim;
        uint256 totalAmount;
        uint256 timeLock;
        uint256 amountPerClaim;
        uint256 claimed;
    }

    DistributionItem[] distributions;

    constructor(
        address _owner,
        address _walletTeam,
        address _walletPartners,
        address _walletGiveways,
        address _walletLiquidityExchange,
        address _walletLaunch,
        address _walletStake,
        address _walletFounder
    ) {
        startDateDistribution = block.timestamp;
        tokenConfigured = false;

        walletTeam = _walletTeam;
        walletPartners = _walletPartners;
        walletGiveways = _walletGiveways;
        walletLiquidityExchange = _walletLiquidityExchange;
        walletLaunch = _walletLaunch;
        walletStake = _walletStake;
        walletFounder = _walletFounder;

        configureTimeLocks();

        // Transfer ownership if sender is not the _owner
        if (msg.sender != _owner) {
            transferOwnership(_owner);
        }
    }

    function configureTokenAddress(address _token) public onlyOwner {
        // We need to configure token after token was created, but token needs Distribution contract.
        require(!tokenConfigured);
        token = IERC20(_token);
        tokenConfigured = true;

        sendPredefinedTokens(walletLaunch);
    }

    function configureTimeLocks() private {
        
        // Wallet Founder will get all tokens after 24 hours
        distributions.push(
            DistributionItem(
                walletFounder,
                startDateDistribution,
                10000000 * 10**18,
                oneDay,
                10000000 * 10**18,
                0
            )
        );
        // Wallet Team will gonna claim each month 500000 tokens until it gets 10000000
        distributions.push(
            DistributionItem(
                walletTeam,
                startDateDistribution,
                10000000 * 10**18,
                oneMonth,
                500000 * 10**18,
                0
            )
        );
        // Wallet Partners will gonna claim each month 500000 tokens until it gets 10000000
        distributions.push(
            DistributionItem(
                walletPartners,
                startDateDistribution,
                10000000 * 10**18,
                oneMonth,
                500000 * 10**18,
                0
            )
        );
        // Wallet Giveways will gonna claim each month 500000 tokens until it gets 10000000
        distributions.push(
            DistributionItem(
                walletGiveways,
                startDateDistribution,
                10000000 * 10**18,
                oneMonth,
                500000 * 10**18,
                0
            )
        );

        // Wallet Stake will gonna claim each month 500000 tokens until it gets 10000000
        distributions.push(
            DistributionItem(
                walletStake,
                startDateDistribution,
                10000000 * 10**18,
                oneMonth,
                500000 * 10**18,
                0
            )
        );

        // Wallet Liquidity Exchange will gonna claim each six month 5000000 tokens until it gets 20000000
        distributions.push(
            DistributionItem(
                walletLiquidityExchange,
                startDateDistribution,
                20000000 * 10**18,
                sixMonths,
                5000000 * 10**18,
                0
            )
        );
    }

    function sendPredefinedTokens(
        address _walletLaunch
    ) private {
        require(
            token.transfer(_walletLaunch, 30000000 * 10**18),
            "Error to send initial tokens to WalletLaunch"
        );
    }

    function verifyTimeLock() external view returns (bool availableClaim) {
        for (uint256 i = 0; i < distributions.length; i++) {
            if (
                (distributions[i].claimed < distributions[i].totalAmount) &&
                (block.timestamp >=
                    distributions[i].lastClaim + distributions[i].timeLock)
            ) {
                return true;
            }
        }
    }

    function claim() external onlyOwner {
        for (uint256 i = 0; i < distributions.length; i++) {
            if (
                block.timestamp >=
                distributions[i].lastClaim + distributions[i].timeLock
            ) {
                if (distributions[i].claimed < distributions[i].totalAmount) {
                    distributions[i].claimed += distributions[i].amountPerClaim;
                    distributions[i].lastClaim = block.timestamp;
                    require(
                        token.transfer(
                            distributions[i].wallet,
                            distributions[i].amountPerClaim
                        ),
                        "error to send tokens to Wallet"
                    );
                }
            }
        }
    }

    function getTimelocks()
        external
        view
        returns (DistributionItem[] memory _timelocks)
    {
        return distributions;
    }
}