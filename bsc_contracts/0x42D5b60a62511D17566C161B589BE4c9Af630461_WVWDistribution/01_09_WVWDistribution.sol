// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract WVWDistribution is AccessControl {

    bytes32 public constant CONFIG_ROLE = keccak256("CONFIG_ROLE");

    IERC20 public token;
    uint256 public startDateDistribution;
    bool tokenConfigured;

    uint256 oneMonth = 30 days;
    uint256 sixMonths = 180 days;

    address public owner;
    address public walletTeam;
    address public walletPartners;
    address public walletGiveways;
    address public walletLiquidityExchange;
    address public walletLaunch;
    address public walletPreSale;
    address public walletFounder;

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
        address _developer,
        address _owner,
        address _walletTeam,
        address _walletPartners,
        address _walletGiveways,
        address _walletLiquidityExchange,
        address _walletLaunch,
        address _walletPreSale,
        address _walletFounder
    ) {
        startDateDistribution = block.timestamp;
        tokenConfigured = false;

        owner = _owner;
        walletTeam = _walletTeam;
        walletPartners = _walletPartners;
        walletGiveways = _walletGiveways;
        walletLiquidityExchange = _walletLiquidityExchange;
        walletLaunch = _walletLaunch;
        walletPreSale = _walletPreSale;
        walletFounder = _walletFounder;

        _grantRole(DEFAULT_ADMIN_ROLE, owner);
        _grantRole(CONFIG_ROLE, _developer);

        configureTimeLocks();
    }

    function configureTokenAddress(address _token)
        public
        onlyRole(CONFIG_ROLE)
    {
        // We need to configure token after token was created, but token needs Distribution contract.
        require(!tokenConfigured);
        token = IERC20(_token);
        tokenConfigured = true;

        sendPredefinedTokens(walletLaunch, walletPreSale, walletFounder);
    }

    function configureTimeLocks() private {
        distributions.push(
            DistributionItem(
                walletTeam,
                startDateDistribution,
                10000000 * 10**18,
                oneMonth,
                500000,
                0
            )
        );
        distributions.push(
            DistributionItem(
                walletPartners,
                startDateDistribution,
                10000000 * 10**18,
                oneMonth,
                500000,
                0
            )
        );
        distributions.push(
            DistributionItem(
                walletGiveways,
                startDateDistribution,
                10000000 * 10**18,
                oneMonth,
                500000,
                0
            )
        );
        distributions.push(
            DistributionItem(
                walletLiquidityExchange,
                startDateDistribution,
                20000000 * 10**18,
                sixMonths,
                5000000,
                0
            )
        );
    }

    function sendPredefinedTokens(
        address _walletLaunch,
        address _walletPreSale,
        address _walletFounder
    ) private {
        token.transfer(_walletLaunch, 30000000 * 10**18);
        token.transfer(_walletPreSale, 10000000 * 10**18);
        token.transfer(_walletFounder, 10000000 * 10**18);
    }

    function verifyTimeLock() public view returns (bool availableClaim) {
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

    function claim() public onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint256 i = 0; i < distributions.length; i++) {
            if (
                block.timestamp >=
                distributions[i].lastClaim + distributions[i].timeLock
            ) {
                if (distributions[i].claimed < distributions[i].totalAmount) {
                    distributions[i].claimed =
                        distributions[i].claimed +
                        distributions[i].amountPerClaim;
                    distributions[i].lastClaim = block.timestamp;
                    token.transfer(
                        distributions[i].wallet,
                        distributions[i].amountPerClaim
                    );
                }
            }
        }
    }

    function getTimelocks()
        public
        view
        returns (DistributionItem[] memory _timelocks)
    {
        return distributions;
    }
}