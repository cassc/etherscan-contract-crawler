// SPDX-License-Identifier: SPWPL
pragma solidity 0.8.15;

import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/proxy/utils/Initializable.sol";
import "openzeppelin-solidity/contracts/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin-solidity/contracts/security/ReentrancyGuard.sol";
import "@opengsn/contracts/src/ERC2771Recipient.sol";
import "hardhat/console.sol";

/*******************************
 * @title Revenue Path V2
 * @notice The revenue path clone instance contract.
 */

interface IReveelPathFactory {
    function getPlatformWallet() external view returns (address);
}

contract ReveelPathInstance is
    ERC2771Recipient,
    Ownable,
    Initializable,
    ReentrancyGuard
{
    using SafeERC20 for IERC20;

    uint32 public constant BASE = 1e7;
    uint8 public constant VERSION = 2;

    bool private feeRequired;

    bool private isImmutable;

    uint32 private platformFee;

    address private mainFactory;

    bytes32 private pathHash;

    uint256 private totalTiers;

    /**
     * @notice For a given token & wallet address, returns the amount of token released
     */
    mapping(address => mapping(address => uint256)) private released;
    /**
     * @notice For a given token & tier number the token limit amount is returned
     */
    mapping(address => mapping(uint256 => uint256)) private tokenTierLimits;
    /**
     * @notice Maps token address to ongoing active token tier for that token
     */
    mapping(address => uint256) private currentTokenTier;
    /**
     * @notice Maps token address to the amount of token released from the path
     */
    mapping(address => uint256) private totalTokenReleased;
    /**
     * @notice Maps token address to the amount of token gone through accounting in the path
     */
    mapping(address => uint256) private totalTokenAccounted;

    /**
     *   @notice For a given token & wallet address, the amount of the token that can been withdrawn by the wallet
    [token][wallet]
    */
    mapping(address => mapping(address => uint256)) private tokenWithdrawable;
    /**
     * @notice For a given token & tiernumber, the total distributed in that tier is returned.
     */
    mapping(address => mapping(uint256 => uint256)) private totalDistributed;

    /**
     * @notice For a given token the amount of fee that has been accumulated is returned.
     */
    mapping(address => uint256) private feeAccumulated;

    struct PathInfo {
        uint32 platformFee;
        bool isImmutable;
        address factory;
        address forwarder;
    }

    /********************************
     *           EVENTS              *
     ********************************/

    /** @notice Emits when token payment is withdrawn/claimed by a member
     * @param account The wallet for which ETH has been claimed for
     * @param payment The amount of ETH that has been paid out to the wallet
     */
    event PaymentReleased(
        address indexed account,
        address indexed token,
        uint256 indexed payment
    );

    /** @notice Emits when ERC20 payment is withdrawn/claimed by a member
     * @param token The token address for which withdrawal is made
     * @param account The wallet address to which withdrawal is made
     * @param payment The amount of the given token the wallet has claimed
     */
    event ERC20PaymentReleased(
        address indexed token,
        address indexed account,
        uint256 indexed payment
    );

    /** @notice Emits when tokens are distributed during withdraw or external distribution call
     *  @param token Address of token for distribution. Zero address for native token like ETH
     *  @param amount The amount of token distributed in wei
     *  @param tier The tier for which the distribution occured
     */
    event TokenDistributed(
        address indexed token,
        uint256 indexed amount,
        uint256 indexed tier
    );

    /** @notice Emits on receive; mimics ERC20 Transfer
     *  @param from Address that deposited the eth
     *  @param value Amount of ETH deposited
     */
    event DepositETH(address indexed from, uint256 value);

    /**
     *  @notice Emits when fee is distributed
     *  @param token The token address. Address 0 for native gas token like ETH
     *  @param amount The amount of fee deducted
     */
    event FeeDistributed(address indexed token, uint256 indexed amount);

    /**
     *  @notice Emits when fee is released
     *  @param token The token address. Address 0 for native gas token like ETH
     *  @param amount The amount of fee released
     */
    event FeeReleased(address indexed token, uint256 indexed amount);

    /**
     * emits when one or more revenue tiers are added
     *  @param wallets Array of arrays of wallet lists (each array is a tier)
     *  @param distributions Array of arrays of distr %s (each array is a tier)
     */
    event RevenueTierAdded(address[][] wallets, uint256[][] distributions);

    /**
     * emits when one or more revenue tiers wallets/distributions are updated
     *  @param tierNumbers Array tier numbers being updated
     *  @param wallets Array of arrays of wallet lists (each array is a tier)
     *  @param distributions Array of arrays of distr %s (each array is a tier)
     */
    event RevenueTierUpdated(
        uint256[] tierNumbers,
        address[][] wallets,
        uint256[][] distributions
    );

    /**
     * emits when one revenue tier's limit is updated
     *  @param tier tier number being updated
     *  @param tokenList Array of tokens in that tier
     *  @param newLimits Array of limits for those tokens
     */
    event TierLimitUpdated(
        uint256 tier,
        address[] tokenList,
        uint256[] newLimits
    );

    /********************************
     *           MODIFIERS          *
     ********************************/
    /** @notice Entrant guard for mutable contract methods
     */
    modifier isMutable() {
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
    error WalletAndDistrbutionCtMismatch(
        uint256 walletCount,
        uint256 distributionCount
    );

    /** @dev Reverts when the member has zero  withdrawal balance available
     */
    error NoDuePayment(address wallet);

    /** @dev Reverts when immutable path attempts to use mutable methods
     */
    error RevenuePathNotMutable();

    /** @dev Reverts when contract has insufficient token for withdrawal
     * @param contractBalance  The total balance of token available in the contract
     * @param requiredAmount The total amount of token requested for withdrawal
     */
    error InsufficentBalance(uint256 contractBalance, uint256 requiredAmount);

    /**
     * @dev In case invalid zero address is provided for wallet address
     */
    error ZeroAddressProvided();

    /**
     * @dev Reverts when zero distribution percentage is provided
     */
    error ZeroDistributionProvided();

    /**
     * @dev Reverts when summation of distirbution is not equal to BASE
     */
    error TotalShareNot100();

    /**
     * @dev Reverts when a tier not in existence or added is attempted for update
     */
    error OnlyExistingTiersCanBeUpdated();

    /**
     * @dev Reverts when token already released is greater than the new limit that's being set for the tier.
     */
    error TokenLimitNotValid();

    /**
     *  @dev Reverts when tier limit given is zero in certain cases
     */
    error TierLimitGivenZero();

    /**
     * @dev Reverts when tier limit of a non-existant tier is attempted
     */
    error OnlyExistingTierLimitsCanBeUpdated();

    /**
     * @dev The total numb of tokens and equivalent token limit list count mismatch
     */
    error TokensAndTierLimitMismatch(
        uint256 tokenCount,
        uint256 limitListCount
    );

    /**
     * @dev The total tiers list and limits list length mismatch
     */
    error TotalTierLimitsMismatch(uint256 tiers, uint256 limits);

    /**
     * @dev Reverts when final tier is attempted for updates
     */
    error FinalTierLimitNotUpdatable();
    /**
     * @dev Reverts when the path hash validated against the existing is invalid
     */
    error InvalidPathHash();

    /**
     * @dev Reverts when an empty array list is provided
     */
    error EmptyListProvided();

    /********************************
     *           FUNCTIONS           *
     ********************************/

    /**
     * @notice Receive ETH
     */
    receive() external payable {
        emit DepositETH(_msgSender(), msg.value);
    }

    /** @notice Called for a given token to distribute, unallocated tokens to the respective tiers and wallet members
     *  @param token The address of the token
     *  @param _walletList the nested array of wallet list of all the tiers
     *  @param _distribution the nested array of distribution of the corresponding wallets of all the tiers.
     */
    function distributePendingTokens(
        address token,
        address[][] memory _walletList,
        uint256[][] memory _distribution
    ) external nonReentrant {
        _distributePendingTokens(token, _walletList, _distribution);
    }

    /** @notice Get the token amount that has not been allocated for in the revenue path
     *  @param token The token address
     */
    function getPendingDistributionAmount(
        address token
    ) public view returns (uint256) {
        uint256 pathTokenBalance;
        if (token == address(0)) {
            pathTokenBalance = address(this).balance;
        } else {
            pathTokenBalance = IERC20(token).balanceOf(address(this));
        }
        uint256 _pendingAmount = (pathTokenBalance +
            totalTokenReleased[token]) - totalTokenAccounted[token];
        return _pendingAmount;
    }

    /** @notice Initializes revenue path
     *  @param _walletList Nested array for wallet list across different tiers
     *  @param _distribution Nested array for distribution percentage across different tiers
     *  @param _tokenList A list of tokens for which limits will be set
     *  @param _limitSequence A nested array of limits for each token
     *  @param pathInfo A property object for the path details
     *  @param _owner Address of path owner
     */
    function initialize(
        address[][] memory _walletList,
        uint256[][] memory _distribution,
        address[] calldata _tokenList,
        uint256[][] memory _limitSequence,
        PathInfo calldata pathInfo,
        address _owner
    ) external initializer {
        _validatePath(_walletList, _distribution, _tokenList, _limitSequence);
        _generatePathHash(_walletList, _distribution);
        mainFactory = pathInfo.factory;
        platformFee = pathInfo.platformFee;
        isImmutable = pathInfo.isImmutable;
        totalTiers = _walletList.length;

        _transferOwnership(_owner);
        _setTrustedForwarder(pathInfo.forwarder);
    }

    /** @notice Adding new revenue tiers
     *  @param _addWalletList a nested list of new wallets
     *  @param _addDistribution a nested list of corresponding distribution
     */
    function addRevenueTiers(
        address[][] memory _walletList,
        uint256[][] memory _distribution,
        address[][] calldata _addWalletList,
        uint256[][] calldata _addDistribution
    ) external isMutable onlyOwner {
        _validatePathHash(_walletList, _distribution);
        uint256 listLength = _addWalletList.length;
        if (listLength == 0) {
            revert EmptyListProvided();
        }
        if (listLength != _addDistribution.length) {
            revert WalletAndDistrbutionCtMismatch({
                walletCount: listLength,
                distributionCount: _addDistribution.length
            });
        }

        uint256 nextRevenueTier = totalTiers;

        // Resize _walletList and _distribution arrays
        uint256 newLength = _walletList.length + listLength;
        address[][] memory newWalletList = new address[][](newLength);
        uint256[][] memory newDistribution = new uint256[][](newLength);

        // Copy existing elements
        for (uint256 i = 0; i < _walletList.length; i++) {
            newWalletList[i] = _walletList[i];
            newDistribution[i] = _distribution[i];
        }

        // Add new elements
        for (uint256 i = 0; i < listLength; i++) {
            uint256 walletMembers = _addWalletList[i].length;

            if (walletMembers != _addDistribution[i].length) {
                revert WalletAndDistrbutionCtMismatch({
                    walletCount: walletMembers,
                    distributionCount: _addDistribution[i].length
                });
            }
            uint256 totalShares;
            for (uint256 j = 0; j < walletMembers; j++) {
                if ((_addWalletList[i])[j] == address(0)) {
                    revert ZeroAddressProvided();
                }
                if ((_addDistribution[i])[j] == 0) {
                    revert ZeroDistributionProvided();
                }
                totalShares += (_addDistribution[i])[j];
            }

            newWalletList[_walletList.length + i] = _addWalletList[i];
            newDistribution[_walletList.length + i] = _addDistribution[i];

            if (totalShares != BASE) {
                revert TotalShareNot100();
            }
            nextRevenueTier += 1;
        }
        if (!feeRequired) {
            feeRequired = true;
        }

        _generatePathHash(newWalletList, newDistribution);

        totalTiers += listLength;

        emit RevenueTierAdded(newWalletList, newDistribution);
    }

    /** @notice Updating distribution for existing revenue tiers
     *  @param _updatedWalletList A nested list of wallet address
     *  @param _updatedDistribution A nested list of distribution percentage
     *  @param _tierNumbers A list of tier numbers to be updated
     */
    function updateRevenueTiers(
        address[][] memory _walletList,
        uint256[][] memory _distribution,
        address[][] memory _updatedWalletList,
        uint256[][] memory _updatedDistribution,
        uint256[] memory _tierNumbers
    ) external isMutable onlyOwner {
        _validatePathHash(_walletList, _distribution);
        uint256 totalUpdates = _tierNumbers.length;
        if (totalUpdates == 0) {
            revert EmptyListProvided();
        }
        if (
            _updatedWalletList.length != _updatedDistribution.length ||
            _updatedWalletList.length != totalUpdates
        ) {
            revert WalletAndDistrbutionCtMismatch({
                walletCount: _updatedWalletList.length,
                distributionCount: _updatedDistribution.length
            });
        }

        for (uint256 i; i < totalUpdates; ) {
            uint256 totalWallets = _updatedWalletList[i].length;
            if (totalWallets != _updatedDistribution[i].length) {
                revert WalletAndDistrbutionCtMismatch({
                    walletCount: _updatedWalletList[i].length,
                    distributionCount: _updatedDistribution[i].length
                });
            }
            uint256 tier = _tierNumbers[i];
            if (tier >= totalTiers) {
                revert OnlyExistingTiersCanBeUpdated();
            }

            uint256 totalShares;
            address[] memory newWalletList = new address[](totalWallets);
            for (uint256 j; j < totalWallets; ) {
                address wallet = (_updatedWalletList[i])[j];

                if (wallet == address(0)) {
                    revert ZeroAddressProvided();
                }
                if ((_updatedDistribution[i])[j] == 0) {
                    revert ZeroDistributionProvided();
                }

                totalShares += (_updatedDistribution[i])[j];
                newWalletList[j] = wallet;

                unchecked {
                    j++;
                }
            }

            _walletList[tier] = _updatedWalletList[i];
            _distribution[tier] = _updatedDistribution[i];

            if (totalShares != BASE) {
                revert TotalShareNot100();
            }
            unchecked {
                i++;
            }
        }

        _generatePathHash(_walletList, _distribution);
        emit RevenueTierUpdated(
            _tierNumbers,
            _updatedWalletList,
            _updatedDistribution
        );
    }

    /** @notice Update tier limits for given tokens for an existing tier
     * @param tokenList A list of tokens for which limits will be updated
     * @param newLimits A list of corresponding limits for the tokens
     * @param tier The tier for which limits are being updated
     */
    function updateLimits(
        address[] calldata tokenList,
        uint256[] calldata newLimits,
        uint256 tier
    ) external isMutable onlyOwner {
        uint256 listCount = tokenList.length;
        if (listCount == 0) {
            revert EmptyListProvided();
        }
        if (listCount != newLimits.length) {
            revert TokensAndTierLimitMismatch({
                tokenCount: listCount,
                limitListCount: newLimits.length
            });
        }
        if (tier >= totalTiers) {
            revert OnlyExistingTierLimitsCanBeUpdated();
        }

        if (tier == totalTiers - 1) {
            revert FinalTierLimitNotUpdatable();
        }

        for (uint256 i; i < listCount; ) {
            if (totalDistributed[tokenList[i]][tier] > newLimits[i]) {
                revert TokenLimitNotValid();
            }
            tokenTierLimits[tokenList[i]][tier] = newLimits[i];

            unchecked {
                i++;
            }
        }
        emit TierLimitUpdated(tier, tokenList, newLimits);
    }

    /** @notice Releases distribute token
     * @param token The token address
     * @param accounts The address of the receivers
     */

    function release(
        address token,
        address payable[] memory accounts,
        address[][] memory _walletList,
        uint256[][] memory _distribution,
        bool shouldDistribute
    ) external nonReentrant {
        if (shouldDistribute) {
            _distributePendingTokens(token, _walletList, _distribution);
        }

        uint256 _totalTokenReleased;
        uint256 payment;

        if (token == address(0)) {
            unchecked {
                for (uint256 i; i < accounts.length; ) {
                    payment = tokenWithdrawable[token][accounts[i]];
                    if (payment == 0) {
                        revert NoDuePayment({wallet: accounts[i]});
                    }
                    released[token][accounts[i]] += payment;
                    _totalTokenReleased += payment;
                    tokenWithdrawable[token][accounts[i]] = 0;
                    sendValue(accounts[i], payment);
                    emit PaymentReleased(accounts[i], token, payment);

                    i++;
                }
            } //For loop ends

            totalTokenReleased[token] += _totalTokenReleased;

            if (feeAccumulated[token] > 0) {
                uint256 value = feeAccumulated[token];
                feeAccumulated[token] = 0;
                totalTokenReleased[token] += value;
                address platformFeeWallet = IReveelPathFactory(mainFactory)
                    .getPlatformWallet();
                sendValue(payable(platformFeeWallet), value);
                emit FeeReleased(token, value);
            }
        } else {
            unchecked {
                for (uint256 i; i < accounts.length; ) {
                    payment = tokenWithdrawable[token][accounts[i]];
                    if (payment == 0) {
                        revert NoDuePayment({wallet: accounts[i]});
                    }
                    released[token][accounts[i]] += payment;
                    _totalTokenReleased += payment;
                    tokenWithdrawable[token][accounts[i]] = 0;
                    IERC20(token).safeTransfer(accounts[i], payment);
                    emit ERC20PaymentReleased(token, accounts[i], payment);

                    i++;
                }
            } //For loop ends

            totalTokenReleased[token] += _totalTokenReleased;
            if (feeAccumulated[token] > 0) {
                uint256 value = feeAccumulated[token];
                feeAccumulated[token] = 0;
                totalTokenReleased[token] += value;
                address platformFeeWallet = IReveelPathFactory(mainFactory)
                    .getPlatformWallet();
                IERC20(token).safeTransfer(platformFeeWallet, value);
                emit FeeReleased(token, value);
            }
        }
    }

    /** @notice Get the totalNumber of revenue tiers in the revenue path
     */
    function getTotalRevenueTiers() external view returns (uint256 total) {
        return totalTiers;
    }

    /** @notice Get the current ongoing tier of revenue path
     * For eth: token address(0) is reserved
     */
    function getCurrentTier(
        address token
    ) external view returns (uint256 tierNumber) {
        return currentTokenTier[token];
    }

    /** @notice Get the current ongoing tier of revenue path
     */
    function getFeeRequirementStatus() external view returns (bool required) {
        return feeRequired;
    }

    /** @notice Get the amount of token distrbuted for a given tier
     *  @param token The token address for which distributed amount is fetched
     *  @param tier The tier for which distributed amount is fetched
     */

    function getTierDistributedAmount(
        address token,
        uint256 tier
    ) external view returns (uint256 amount) {
        return totalDistributed[token][tier];
    }

    /** @notice Get the amount of ETH accumulated for fee collection
     */

    function getTotalFeeAccumulated(
        address token
    ) external view returns (uint256 amount) {
        return feeAccumulated[token];
    }

    /** @notice Get the amount of token released for a given account
     *  @param token the token address for which token released is fetched
     *  @param account the wallet address for whih the token released is fetched
     */

    function getTokenReleased(
        address token,
        address account
    ) external view returns (uint256 amount) {
        return released[token][account];
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

    /** @notice Get the amount of total eth withdrawn by the account
     */
    function getTokenWithdrawn(
        address token,
        address account
    ) external view returns (uint256) {
        return released[token][account];
    }

    function getTokenTierLimits(
        address token,
        uint256 tier
    ) external view returns (uint256) {
        return tokenTierLimits[token][tier];
    }

    /** @notice Update the trusted forwarder address
     *  @param forwarder The address of the new forwarder
     *
     */
    function setTrustedForwarder(address forwarder) external onlyOwner {
        _setTrustedForwarder(forwarder);
    }

    /**
     * @notice Returns total token released
     * @param token The token for which total released amount is fetched
     */
    function getTotalTokenReleased(
        address token
    ) external view returns (uint256) {
        return totalTokenReleased[token];
    }

    /**
     * @notice Returns total token accounted for a given token address
     * @param token The token for which total accounted amount is fetched
     */
    function getTotalTokenAccounted(
        address token
    ) external view returns (uint256) {
        return totalTokenAccounted[token];
    }

    /**
     * @notice Returns withdrawable or claimable token amount for a given wallet in the revenue path
     */
    function getWithdrawableToken(
        address token,
        address wallet
    ) external view returns (uint256) {
        return tokenWithdrawable[token][wallet];
    }

    /**
     * @notice Returns the ReveelPathFactory contract address
     */
    function getMainFactory() external view returns (address) {
        return mainFactory;
    }

    function getRevenuePathHash() external view returns (bytes32) {
        return pathHash;
    }

    /** @notice Transfer handler for ETH
     * @param recipient The address of the receiver
     * @param amount The amount of ETH to be received
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "ETH_TRANSFER_FAILED");
    }

    function _msgSender()
        internal
        view
        virtual
        override(Context, ERC2771Recipient)
        returns (address ret)
    {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            assembly {
                ret := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            ret = msg.sender;
        }
    }

    function _msgData()
        internal
        view
        virtual
        override(Context, ERC2771Recipient)
        returns (bytes calldata ret)
    {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            return msg.data[0:msg.data.length - 20];
        } else {
            return msg.data;
        }
    }

    /**
     * @notice Generates a path hash that is unique for the given walletList & distribution
     */
    function _generatePathHash(
        address[][] memory _walletList,
        uint256[][] memory _distribution
    ) private {
        pathHash = keccak256(abi.encode(_walletList, _distribution));
    }

    /**
     * @notice Validates the passed path details against the existing path hash
     */
    function _validatePathHash(
        address[][] memory _walletList,
        uint256[][] memory _distribution
    ) private view {
        bytes32 newPathHash = keccak256(abi.encode(_walletList, _distribution));

        if (newPathHash != pathHash) {
            revert InvalidPathHash();
        }
    }

    /**
     * @notice Validates all path details.
     */
    function _validatePath(
        address[][] memory _walletList,
        uint256[][] memory _distribution,
        address[] memory _tokenList,
        uint256[][] memory _limitSequence
    ) internal {
        totalTiers = _walletList.length;
        uint256 totalTokens = _tokenList.length;
        if (totalTiers != _distribution.length) {
            revert WalletAndDistrbutionCtMismatch({
                walletCount: _walletList.length,
                distributionCount: _distribution.length
            });
        }

        if (totalTokens != _limitSequence.length) {
            revert TokensAndTierLimitMismatch({
                tokenCount: totalTokens,
                limitListCount: _limitSequence.length
            });
        }
        for (uint256 i; i < totalTiers; ) {
            uint256 walletMembers = _walletList[i].length;

            if (walletMembers != _distribution[i].length) {
                revert WalletAndDistrbutionCtMismatch({
                    walletCount: walletMembers,
                    distributionCount: _distribution[i].length
                });
            }

            uint256 totalShare;
            for (uint256 j; j < walletMembers; ) {
                address wallet = (_walletList[i])[j];

                if (wallet == address(0)) {
                    revert ZeroAddressProvided();
                }
                if ((_distribution[i])[j] == 0) {
                    revert ZeroDistributionProvided();
                }

                totalShare += (_distribution[i])[j];
                unchecked {
                    j++;
                }
            }
            if (totalShare != BASE) {
                revert TotalShareNot100();
            }

            unchecked {
                i++;
            }
        }

        for (uint256 k; k < totalTokens; ) {
            address token = _tokenList[k];

            if ((totalTiers - 1) != _limitSequence[k].length) {
                revert TotalTierLimitsMismatch({
                    tiers: totalTiers,
                    limits: _limitSequence[k].length
                });
            }
            for (uint256 m; m < totalTiers - 1; ) {
                if (_limitSequence[k][m] == 0) {
                    revert TierLimitGivenZero();
                }
                tokenTierLimits[token][m] = _limitSequence[k][m];

                unchecked {
                    m++;
                }
            }

            unchecked {
                k++;
            }
        }

        if (totalTiers > 1) {
            feeRequired = true;
        }
    }

    /** @notice Called for a given token to distribute, unallocated tokens to the respective tiers and wallet members
     *  @param token The address of the token
     *  @param _walletList the nested array of wallet list of all the tiers
     *  @param _distribution the nested array of distribution of the corresponding wallets of all the tiers.
     */

    function _distributePendingTokens(
        address token,
        address[][] memory _walletList,
        uint256[][] memory _distribution
    ) internal {
        _validatePathHash(_walletList, _distribution);
        uint256 pendingAmount = getPendingDistributionAmount(token);
        uint256 presentTier;
        uint256 currentTierDistribution;
        uint256 tokenLimit;
        uint256 tokenTotalDistributed;
        uint256 nextTierDistribution;
        while (pendingAmount > 0) {
            presentTier = currentTokenTier[token];
            tokenLimit = tokenTierLimits[token][presentTier];
            tokenTotalDistributed = totalDistributed[token][presentTier];
            unchecked {
                if (
                    tokenLimit > 0 &&
                    (tokenTotalDistributed + pendingAmount) > tokenLimit
                ) {
                    currentTierDistribution =
                        tokenLimit -
                        tokenTotalDistributed;
                    nextTierDistribution =
                        pendingAmount -
                        currentTierDistribution;
                } else {
                    currentTierDistribution = pendingAmount;
                    nextTierDistribution = 0;
                }

                if (currentTierDistribution > 0) {
                    address[] memory walletMembers = _walletList[presentTier];
                    uint256 totalWallets = walletMembers.length;
                    uint256 feeDeduction;
                    if (feeRequired && platformFee > 0) {
                        feeDeduction = ((currentTierDistribution *
                            platformFee) / BASE);
                        feeAccumulated[token] += feeDeduction;
                        currentTierDistribution -= feeDeduction;
                        emit FeeDistributed(token, feeDeduction);
                    }

                    for (uint256 i; i < totalWallets; ) {
                        tokenWithdrawable[token][
                            walletMembers[i]
                        ] += ((currentTierDistribution *
                            _distribution[presentTier][i]) / BASE);
                        // unchecked {
                        i++;
                        // }
                    }

                    totalTokenAccounted[token] += (currentTierDistribution +
                        feeDeduction);
                    totalDistributed[token][
                        presentTier
                    ] += (currentTierDistribution + feeDeduction);
                    emit TokenDistributed(
                        token,
                        currentTierDistribution,
                        presentTier
                    );
                }
            }
            pendingAmount = nextTierDistribution;
            if (nextTierDistribution > 0) {
                currentTokenTier[token] += 1;
            }
        }
    }
}