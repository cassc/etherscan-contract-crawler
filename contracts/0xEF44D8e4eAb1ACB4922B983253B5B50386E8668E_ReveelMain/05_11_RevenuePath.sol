// SPDX-License-Identifier: SPWPL
pragma solidity 0.8.9;

import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/proxy/utils/Initializable.sol";
import "openzeppelin-solidity/contracts/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin-solidity/contracts/security/ReentrancyGuard.sol";

/*******************************
 * @title Revenue Path V1
 * @notice The revenue path clone instance contract.
 */
interface IReveelMain {
    function getPlatformWallet() external view returns (address);
}

contract RevenuePath is Ownable, Initializable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    uint256 public constant BASE = 1e4;
    uint8 public constant VERSION = 1;

    //@notice Addres of platform wallet to collect fees
    address private platformFeeWallet;

    //@notice Status to flag if fee is applicable to the revenue paths
    bool private feeRequired;

    //@notice Status to flag if revenue path is immutable. True if immutable
    bool private isImmutable;

    //@notice Fee percentage that will be applicable for additional tiers
    uint88 private platformFee;

    //@notice Current ongoing tier for eth distribution, in case multiple tiers are added
    uint256 private currentTier;

    //@noitce Total fee accumulated by the revenue path and waiting to be collected.
    uint256 private feeAccumulated;

    //@notice Total ETH that has been released/withdrawn by the revenue path members
    uint256 private totalReleased;

    string private name;

    address private mainFactory;

    /// ETH

    // @notice ETH revenue waiting to be collected for a given address
    mapping(address => uint256) private ethRevenuePending;

    /** @notice For a given tier & address, the eth revenue distribution proportion is returned
     *  @dev Index for tiers starts from 0. i.e, the first tier is marked 0 in the list.
     */
    mapping(uint256 => mapping(address => uint256)) private revenueProportion;

    // @notice Amount of ETH release for a given address
    mapping(address => uint256) private released;

    // @notice Total amount of ETH distributed for a given tier at that time.
    mapping(uint256 => uint256) private totalDistributed;

    /// ERC20
    // @notice ERC20 revenue share/proportion for a given address
    mapping(address => uint256) private erc20RevenueShare;

    /**  @notice For a given token & wallet address, the amount of the token that has been released
    . erc20Released[token][wallet]*/
    mapping(address => mapping(address => uint256)) private erc20Released;

    // @notice Total ERC20 released from the revenue path for a given token address
    mapping(address => uint256) private totalERC20Released;

    /**  @notice For a given token & wallet address, the amount of the token that can been withdrawn by the wallet
    . erc20Withdrawable[token][wallet]*/
    mapping(address => mapping(address => uint256)) public erc20Withdrawable;

    // @notice Total ERC20 accounted for the revenue path for a given token address
    mapping(address => uint256) private totalERC20Accounted;

    // array of address having erc20 distribution shares
    address[] private erc20DistributionWallets;

    struct Revenue {
        uint256 limitAmount;
        address[] walletList;
    }

    struct PathInfo {
        uint88 platformFee;
        address platformWallet;
        bool isImmutable;
        string name;
        address factory;
    }

    Revenue[] private revenueTiers;

    /********************************
     *           EVENTS              *
     ********************************/

    /** @notice Emits when incoming ETH is distributed among members
     * @param amount The amount of eth that has been distributed in a tier
     * @param distributionTier the tier index at which the distribution is being done.
     * @param walletList the list of wallet addresses for which ETH has been distributed
     */
    event EthDistributed(uint256 indexed amount, uint256 indexed distributionTier, address[] walletList);

    /** @notice Emits when ETH payment is withdrawn/claimed by a member
     * @param account The wallet for which ETH has been claimed for
     * @param payment The amount of ETH that has been paid out to the wallet
     */
    event PaymentReleased(address indexed account, uint256 indexed payment);

    /** @notice Emits when ERC20 payment is withdrawn/claimed by a member
     * @param token The token address for which withdrawal is made
     * @param account The wallet address to which withdrawal is made
     * @param payment The amount of the given token the wallet has claimed
     */
    event ERC20PaymentReleased(address indexed token, address indexed account, uint256 indexed payment);

    /** @notice Emits when new revenue tier is added
     * @param addedWalletLists The nested wallet list of different tiers
     * @param addedDistributionLists The corresponding shares of all tiers
     * @param newTiersCount The total number of new tiers added
     */
    event RevenueTiersAdded(
        address[][] addedWalletLists,
        uint256[][] addedDistributionLists,
        uint256 indexed newTiersCount
    );

    /** @notice Emits when revenue tiers are updated
     * @param updatedWalletList The wallet list of different tiers
     * @param updatedDistributionLists The corresponding shares of all tiers
     * @param updatedTierNumber The number of the updated tier
     * @param newLimit The limit of the updated tier
     */
    event RevenueTiersUpdated(
        address[] updatedWalletList,
        uint256[] updatedDistributionLists,
        uint256 indexed updatedTierNumber,
        uint256 indexed newLimit
    );

    /** @notice Emits when erc20 revenue list is are updated
     * @param updatedWalletList The wallet list of different tiers
     * @param updatedDistributionList The corresponding shares of all tiers
     */
    event ERC20RevenueUpdated(address[] updatedWalletList, uint256[] updatedDistributionList);

    /** @notice Emits when erc20 revenue accounting is done
     * @param token The token for which accounting has been done
     * @param amount The amount of token that has been accounted for
     */
    event ERC20Distributed(address indexed token, uint256 indexed amount);

    /********************************
     *           MODIFIERS          *
     ********************************/
    /** @notice Entrant guard for mutable contract methods
     */
    modifier isAllowed() {
        // require(!isImmutable, "IMMUTABLE_PATH_CAN_NOT_USE_THIS");
        if (isImmutable) {
            revert RevenuePathNotMutable();
        }
        _;
    }

    /********************************
     *           ERRORS          *
     ********************************/

    /** @dev Reverts when passed wallet list and distribution list length is not equal
     * @param walletCount Length of wallet list
     * @param distributionCount Length of distribution list
     */
    error WalletAndDistributionCountMismatch(uint256 walletCount, uint256 distributionCount);

    /** @dev Reverts when passed wallet list and tier limit count doesn't add up.
       The tier limit count should be 1 less than wallet list
     * @param walletCount  Length of wallet list
     * @param tierLimitCount Length of tier limit list
     */
    error WalletAndTierLimitMismatch(uint256 walletCount, uint256 tierLimitCount);

    /** @dev Reverts when zero address is assigned
     */
    error ZeroAddressProvided();

    /** @dev Reverts when limit is not greater than already distributed amount for the given tier
     * @param alreadyDistributed The amount of ETH that has already been distributed for that tier
     * @param proposedNewLimit The amount of ETH proposed to be added/updated as limit for the given tier
     */
    error LimitNotGreaterThanTotalDistributed(uint256 alreadyDistributed, uint256 proposedNewLimit);

    /** @dev Reverts when the tier is not eligible for being updated.
      Requested tier for update must be greater than or equal to current tier.
     * @param currentTier The ongoing tier for distribution
     * @param requestedTier The tier which is requested for an update
     */
    error IneligibileTierUpdate(uint256 currentTier, uint256 requestedTier);

    /** @dev Reverts when the member has zero ETH withdrawal balance available
     */
    error InsufficientWithdrawalBalance();
    /** @dev Reverts when the member has zero percentage shares for ERC20 distribution
     */
    error ZeroERC20Shares(address wallet);

    /** @dev Reverts when wallet has no due ERC20 available for withdrawal
     * @param wallet The member's wallet address
     * @param tokenAddress The requested token address
     */
    error NoDueERC20Payment(address wallet, address tokenAddress);

    /** @dev Reverts when immutable path attempts to use mutable methods
     */
    error RevenuePathNotMutable();

    /** @dev Reverts when contract has insufficient ETH for withdrawal
     * @param contractBalance  The total balance of ETH available in the contract
     * @param requiredAmount The total amount of ETH requested for withdrawal
     */
    error InsufficentBalance(uint256 contractBalance, uint256 requiredAmount);

    /**
     * @dev Reverts when sum of all distribution is not equal to BASE
     */
    error TotalShareNotHundred();

    /**
     *  @dev Reverts when duplicate wallet entry is present during addition or updates
     */

    error DuplicateWalletEntry();

    /**
     *  @dev Reverts when tier limit given is zero in certain cases
     */

    error TierLimitGivenZero();

    /**
     * @dev Reverts if zero distribution is given for a passed wallet
     */

    error ZeroDistributionProvided();

    /********************************
     *           FUNCTIONS           *
     ********************************/

    /** @notice Contract ETH receiver, triggers distribution. Called when ETH is transferred to the revenue path.
     */
    receive() external payable {
        distributeHoldings(msg.value, currentTier);
    }

    /**
     * @notice Performs accounting and allocation on passed erc20 balances
     * @param token Address of the token being accounted for
     */

    function erc20Accounting(address token) public {
        uint256 pathTokenBalance = IERC20(token).balanceOf(address(this));
        uint256 pendingAmount = (pathTokenBalance + totalERC20Released[token]) - totalERC20Accounted[token];

        if (pendingAmount == 0) {
            return;
        }
        uint256 totalWallets = erc20DistributionWallets.length;

        for (uint256 i; i < totalWallets; ) {
            address account = erc20DistributionWallets[i];
            erc20Withdrawable[token][account] += (pendingAmount * erc20RevenueShare[account]) / BASE;

            unchecked {
                i++;
            }
        }

        totalERC20Accounted[token] += pendingAmount;

        emit ERC20Distributed(token, pendingAmount);
    }

    /** @notice The initializer for revenue path, directly called from the RevenueMain contract.._
     * @param _walletList A nested array list of member wallets
     * @param _distribution A nested array list of distribution percentages
     * @param _tierLimit A list of tier limits
     * @param pathInfo The basic info related to the path
     * @param _owner The owner of the revenue path
     */

    function initialize(
        address[][] memory _walletList,
        uint256[][] memory _distribution,
        uint256[] memory _tierLimit,
        PathInfo memory pathInfo,
        address _owner
    ) external initializer {
        if (_walletList.length != _distribution.length) {
            revert WalletAndDistributionCountMismatch({
                walletCount: _walletList.length,
                distributionCount: _distribution.length
            });
        }

        if ((_walletList.length - 1) != _tierLimit.length) {
            revert WalletAndTierLimitMismatch({ walletCount: _walletList.length, tierLimitCount: _tierLimit.length });
        }

        uint256 listLength = _walletList.length;

        for (uint256 i; i < listLength; ) {
            Revenue memory tier;

            uint256 walletMembers = _walletList[i].length;

            if (walletMembers != _distribution[i].length) {
                revert WalletAndDistributionCountMismatch({
                    walletCount: walletMembers,
                    distributionCount: _distribution[i].length
                });
            }

            tier.walletList = _walletList[i];
            if (i != listLength - 1) {
                if (_tierLimit[i] == 0) {
                    revert TierLimitGivenZero();
                }
                tier.limitAmount = _tierLimit[i];
            }
            uint256 totalShare;
            for (uint256 j; j < walletMembers; ) {
                if (revenueProportion[i][(_walletList[i])[j]] > 0) {
                    revert DuplicateWalletEntry();
                }
                if ((_walletList[i])[j] == address(0)) {
                    revert ZeroAddressProvided();
                }
                if ((_distribution[i])[j] == 0) {
                    revert ZeroDistributionProvided();
                }
                revenueProportion[i][(_walletList[i])[j]] = (_distribution[i])[j];
                totalShare += (_distribution[i])[j];
                unchecked {
                    j++;
                }
            }
            if (totalShare != BASE) {
                revert TotalShareNotHundred();
            }
            revenueTiers.push(tier);

            unchecked {
                i++;
            }
        }

        uint256 erc20WalletMembers = _walletList[listLength - 1].length;
        for (uint256 k; k < erc20WalletMembers; ) {
            address userWallet = (_walletList[listLength - 1])[k];
            erc20RevenueShare[userWallet] = (_distribution[listLength - 1])[k];
            erc20DistributionWallets.push(userWallet);

            unchecked {
                k++;
            }
        }

        if (revenueTiers.length > 1) {
            feeRequired = true;
        }
        platformFeeWallet = pathInfo.platformWallet;

        platformFee = pathInfo.platformFee;
        mainFactory = pathInfo.factory;
        isImmutable = pathInfo.isImmutable;
        name = pathInfo.name;
        _transferOwnership(_owner);
    }

    /** @notice Adds multiple revenue tiers. Only for mutable revenue path
     * @param _walletList A nested array list of member wallets
     * @param _distribution A nested array list of distribution percentages
     * @param previousTierLimit A list of tier limits, starting with the current last tier's new limit.
     */
    function addRevenueTier(
        address[][] calldata _walletList,
        uint256[][] calldata _distribution,
        uint256[] calldata previousTierLimit
    ) external isAllowed onlyOwner {
        if (_walletList.length != _distribution.length) {
            revert WalletAndDistributionCountMismatch({
                walletCount: _walletList.length,
                distributionCount: _distribution.length
            });
        }
        if ((_walletList.length) != previousTierLimit.length) {
            revert WalletAndTierLimitMismatch({
                walletCount: _walletList.length,
                tierLimitCount: previousTierLimit.length
            });
        }

        uint256 listLength = _walletList.length;
        uint256 nextRevenueTier = revenueTiers.length;
        for (uint256 i; i < listLength; ) {
            if (previousTierLimit[i] == 0) {
                revert TierLimitGivenZero();
            }

            if (previousTierLimit[i] < totalDistributed[nextRevenueTier - 1]) {
                revert LimitNotGreaterThanTotalDistributed({
                    alreadyDistributed: totalDistributed[nextRevenueTier - 1],
                    proposedNewLimit: previousTierLimit[i]
                });
            }

            Revenue memory tier;
            uint256 walletMembers = _walletList[i].length;

            if (walletMembers != _distribution[i].length) {
                revert WalletAndDistributionCountMismatch({
                    walletCount: walletMembers,
                    distributionCount: _distribution[i].length
                });
            }
            revenueTiers[nextRevenueTier - 1].limitAmount = previousTierLimit[i];
            tier.walletList = _walletList[i];
            uint256 totalShares;
            for (uint256 j; j < walletMembers; ) {
                if (revenueProportion[nextRevenueTier][(_walletList[i])[j]] > 0) {
                    revert DuplicateWalletEntry();
                }

                if ((_walletList[i])[j] == address(0)) {
                    revert ZeroAddressProvided();
                }
                if ((_distribution[i])[j] == 0) {
                    revert ZeroDistributionProvided();
                }

                revenueProportion[nextRevenueTier][(_walletList[i])[j]] = (_distribution[i])[j];
                totalShares += (_distribution[i])[j];
                unchecked {
                    j++;
                }
            }

            if (totalShares != BASE) {
                revert TotalShareNotHundred();
            }
            revenueTiers.push(tier);
            nextRevenueTier += 1;

            unchecked {
                i++;
            }
        }
        if (!feeRequired) {
            feeRequired = true;
        }

        emit RevenueTiersAdded(_walletList, _distribution, revenueTiers.length);
    }

    /** @notice Update given revenue tier. Only for mutable revenue path
     * @param _walletList A list of member wallets
     * @param _distribution A list of distribution percentages
     * @param newLimit The new limit of the requested tier
     * @param tierNumber The tier index for which update is being requested.
     */
    function updateRevenueTier(
        address[] calldata _walletList,
        uint256[] calldata _distribution,
        uint256 newLimit,
        uint256 tierNumber
    ) external isAllowed onlyOwner {
        if (tierNumber < currentTier || tierNumber > (revenueTiers.length - 1)) {
            revert IneligibileTierUpdate({ currentTier: currentTier, requestedTier: tierNumber });
        }

        if (tierNumber < revenueTiers.length - 1) {
            if (newLimit == 0) {
                revert TierLimitGivenZero();
            }

            if (newLimit < totalDistributed[tierNumber]) {
                revert LimitNotGreaterThanTotalDistributed({
                    alreadyDistributed: totalDistributed[tierNumber],
                    proposedNewLimit: newLimit
                });
            }
        }

        if (_walletList.length != _distribution.length) {
            revert WalletAndDistributionCountMismatch({
                walletCount: _walletList.length,
                distributionCount: _distribution.length
            });
        }

        address[] memory previousWalletList = revenueTiers[tierNumber].walletList;
        uint256 previousWalletListLength = previousWalletList.length;

        for (uint256 i; i < previousWalletListLength; ) {
            revenueProportion[tierNumber][previousWalletList[i]] = 0;
            unchecked {
                i++;
            }
        }

        revenueTiers[tierNumber].limitAmount = (tierNumber == revenueTiers.length - 1) ? 0 : newLimit;

        uint256 listLength = _walletList.length;
        address[] memory newWalletList = new address[](listLength);
        uint256 totalShares;
        for (uint256 j; j < listLength; ) {
            if (revenueProportion[tierNumber][_walletList[j]] > 0) {
                revert DuplicateWalletEntry();
            }

            if (_walletList[j] == address(0)) {
                revert ZeroAddressProvided();
            }
            if (_distribution[j] == 0) {
                revert ZeroDistributionProvided();
            }
            revenueProportion[tierNumber][_walletList[j]] = _distribution[j];
            totalShares += _distribution[j];
            newWalletList[j] = _walletList[j];
            unchecked {
                j++;
            }
        }
        if (totalShares != BASE) {
            revert TotalShareNotHundred();
        }

        revenueTiers[tierNumber].walletList = newWalletList;
        emit RevenueTiersUpdated(_walletList, _distribution, tierNumber, newLimit);
    }

    /** @notice Update ERC20 revenue distribution. Only for mutable revenue path
     * @param _walletList A list of member wallets
     * @param _distribution A list of distribution percentages
     */
    function updateErc20Distribution(address[] calldata _walletList, uint256[] calldata _distribution)
        external
        isAllowed
        onlyOwner
    {
        if (_walletList.length != _distribution.length) {
            revert WalletAndDistributionCountMismatch({
                walletCount: _walletList.length,
                distributionCount: _distribution.length
            });
        }

        uint256 listLength = _walletList.length;
        uint256 previousWalletListLength = erc20DistributionWallets.length;
        uint256 totalShares;

        for (uint256 i; i < previousWalletListLength; ) {
            erc20RevenueShare[erc20DistributionWallets[i]] = 0;
            unchecked {
                i++;
            }
        }

        delete erc20DistributionWallets;

        for (uint256 j; j < listLength; ) {
            if (erc20RevenueShare[_walletList[j]] > 0) {
                revert DuplicateWalletEntry();
            }
            erc20RevenueShare[_walletList[j]] = _distribution[j];
            erc20DistributionWallets.push(_walletList[j]);
            totalShares += _distribution[j];
            unchecked {
                j++;
            }
        }

        if (totalShares != BASE) {
            revert TotalShareNotHundred();
        }

        emit ERC20RevenueUpdated(_walletList, _distribution);
    }

    /** @notice Releases distributed ETH for the provided address
     * @param account The member's wallet address
     */
    function release(address payable account) external {
        if (ethRevenuePending[account] == 0) {
            revert InsufficientWithdrawalBalance();
        }

        uint256 payment = ethRevenuePending[account];
        released[account] += payment;
        totalReleased += payment;
        ethRevenuePending[account] = 0;

        if (feeAccumulated > 0) {
            uint256 value = feeAccumulated;
            feeAccumulated = 0;
            totalReleased += value;
            platformFeeWallet = IReveelMain(mainFactory).getPlatformWallet();
            sendValue(payable(platformFeeWallet), value);
        }

        sendValue(account, payment);
        emit PaymentReleased(account, payment);
    }

    /** @notice Releases allocated ERC20 for the provided address
     * @param token The address of the ERC20 token
     * @param account The member's wallet address
     */
    function releaseERC20(address token, address account) external nonReentrant {
        erc20Accounting(token);
        uint256 payment = erc20Withdrawable[token][account];

        if (payment == 0) {
            revert NoDueERC20Payment({ wallet: account, tokenAddress: token });
        }

        erc20Released[token][account] += payment;
        erc20Withdrawable[token][account] = 0;
        totalERC20Released[token] += payment;

        IERC20(token).safeTransfer(account, payment);

        emit ERC20PaymentReleased(token, account, payment);
    }

    /** @notice Get the limit amoutn & wallet list for a given revenue tier
     * @param tierNumber the index of the tier for which list needs to be provided.
     */
    function getRevenueTier(uint256 tierNumber)
        external
        view
        returns (uint256 _limitAmount, address[] memory _walletList)
    {
        require(tierNumber <= revenueTiers.length, "TIER_DOES_NOT_EXIST");
        uint256 limit = revenueTiers[tierNumber].limitAmount;
        address[] memory listWallet = revenueTiers[tierNumber].walletList;
        return (limit, listWallet);
    }

    /** @notice Get the totalNumber of revenue tiers in the revenue path
     */
    function getTotalRevenueTiers() external view returns (uint256 total) {
        return revenueTiers.length;
    }

    /** @notice Get the current ongoing tier of revenue path
     */
    function getCurrentTier() external view returns (uint256 tierNumber) {
        return currentTier;
    }

    /** @notice Get the current ongoing tier of revenue path
     */
    function getFeeRequirementStatus() external view returns (bool required) {
        return feeRequired;
    }

    /** @notice Get the pending eth balance for given address
     */
    function getPendingEthBalance(address account) external view returns (uint256 pendingAmount) {
        return ethRevenuePending[account];
    }

    /** @notice Get the ETH revenue proportion for a given account at a given tier
     */
    function getRevenueProportion(uint256 tier, address account) external view returns (uint256 proportion) {
        return revenueProportion[tier][account];
    }

    /** @notice Get the amount of ETH distrbuted for a given tier
     */

    function getTierDistributedAmount(uint256 tier) external view returns (uint256 amount) {
        return totalDistributed[tier];
    }

    /** @notice Get the amount of ETH accumulated for fee collection
     */

    function getTotalFeeAccumulated() external view returns (uint256 amount) {
        return feeAccumulated;
    }

    /** @notice Get the amount of ETH accumulated for fee collection
     */

    function getERC20Released(address token, address account) external view returns (uint256 amount) {
        return erc20Released[token][account];
    }

    /** @notice Get the platform wallet address
     */
    function getPlatformWallet() external view returns (address) {
        return platformFeeWallet;
    }

    /** @notice Get the platform fee percentage
     */
    function getPlatformFee() external view returns (uint256) {
        return platformFee;
    }

    /** @notice Get the revenue path Immutability status
     */
    function getImmutabilityStatus() external view returns (bool) {
        return isImmutable;
    }

    /** @notice Get the total amount of eth withdrawn from revenue path
     */
    function getTotalEthReleased() external view returns (uint256) {
        return totalReleased;
    }

    /** @notice Get the revenue path name.
     */
    function getRevenuePathName() external view returns (string memory) {
        return name;
    }

    /** @notice Get the amount of total eth withdrawn by the account
     */
    function getEthWithdrawn(address account) external view returns (uint256) {
        return released[account];
    }

    /** @notice Get the erc20 revenue share percentage for given account
     */
    function getErc20WalletShare(address account) external view returns (uint256) {
        return erc20RevenueShare[account];
    }

    /** @notice Get the total erc2o released from the revenue path.
     */
    function getTotalErc20Released(address token) external view returns (uint256) {
        return totalERC20Released[token];
    }

    /** @notice Get the token amount that has not been accounted for in the revenue path
     */
    function getPendingERC20Account(address token) external view returns (uint256) {
        uint256 pathTokenBalance = IERC20(token).balanceOf(address(this));
        uint256 pendingAmount = (pathTokenBalance + totalERC20Released[token]) - totalERC20Accounted[token];

        return pendingAmount;
    }

    function getTierWalletCount(uint256 tier) external view returns (uint256) {
        return revenueTiers[tier].walletList.length;
    }

    /** @notice Transfer handler for ETH
     * @param recipient The address of the receiver
     * @param amount The amount of ETH to be received
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        if (address(this).balance < amount) {
            revert InsufficentBalance({ contractBalance: address(this).balance, requiredAmount: amount });
        }

        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "ETH_TRANSFER_FAILED");
    }

    /** @notice Distributes received ETH based on the required conditions of the tier sequences
     * @param amount The amount of ETH to be distributed
     * @param presentTier The current tier for which distribution will take place.
     */

    function distributeHoldings(uint256 amount, uint256 presentTier) private {
        uint256 currentTierDistribution = amount;
        uint256 nextTierDistribution;

        if (
            totalDistributed[presentTier] + amount > revenueTiers[presentTier].limitAmount &&
            revenueTiers[presentTier].limitAmount > 0
        ) {
            currentTierDistribution = revenueTiers[presentTier].limitAmount - totalDistributed[presentTier];
            nextTierDistribution = amount - currentTierDistribution;
        }

        uint256 totalDistributionAmount = currentTierDistribution;

        if (platformFee > 0 && feeRequired) {
            uint256 feeDeduction = ((currentTierDistribution * platformFee) / BASE);
            feeAccumulated += feeDeduction;
            currentTierDistribution -= feeDeduction;
        }

        uint256 totalMembers = revenueTiers[presentTier].walletList.length;

        for (uint256 i; i < totalMembers; ) {
            address wallet = revenueTiers[presentTier].walletList[i];
            ethRevenuePending[wallet] += ((currentTierDistribution * revenueProportion[presentTier][wallet]) / BASE);
            unchecked {
                i++;
            }
        }

        totalDistributed[presentTier] += totalDistributionAmount;

        emit EthDistributed(currentTierDistribution, presentTier, revenueTiers[presentTier].walletList);

        if (nextTierDistribution > 0) {
            currentTier += 1;
            return distributeHoldings(nextTierDistribution, currentTier);
        }
    }
}