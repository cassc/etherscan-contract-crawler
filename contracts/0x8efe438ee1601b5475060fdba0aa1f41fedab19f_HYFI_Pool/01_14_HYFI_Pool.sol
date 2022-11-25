// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "../interfaces/IHYFI_RewardsManager.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

// solhint-disable-next-line contract-name-camelcase
contract HYFI_Pool is
    Initializable,
    IHYFI_RewardsManager,
    AccessControlUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /**
     * @dev information about Athena type
     * @param usdAmount - reward equivalent in USD
     * @param rewardTotalAmount - max amount of rewards
     * @param distributedRewardAmount - amount of rewards are already distributed
     * @param userRewardAmount - amount of rewards are already distributed for user
     */
    struct HYFITokenRewardInfo {
        uint256 usdAmount;
        uint256 rewardTotalAmount;
        uint256 distributedRewardAmount;
        mapping(address => uint256) userRewardAmount;
    }

    /// @dev MINTER_ROLE role identifier
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /// @dev HYFI_REWARD_SUPPLIER role identifier
    bytes32 public constant HYFI_REWARD_SUPPLIER =
        keccak256("HYFI_REWARD_SUPPLIER");

    /// @dev HYFI token instance
    IERC20Upgradeable internal _tokenHYFI;

    /// @dev exchange rate for HYFI token to USD
    uint256 internal _exchangeRateHYFI;

    /// @dev tokens decimals multiplier 10^decimals, 1000000000000000000
    uint256 internal _tokenDecimals;

    /**
     * @dev rewards information (for HYFI_50 (id 4) and HYFI_100 (id 5))
     *  uses struct HYFITokenRewardInfo
     *
     *      usdAmount - reward equivalent in USD
     *      rewardTotalAmount - max amount of rewards
     *      distributedRewardAmount - amount of rewards are already distributed
     *      userRewardAmount - amount of rewards are already distributed for user
     */
    mapping(uint256 => HYFITokenRewardInfo) internal _rewards;

    /**
     * @dev event on successful pool withdrawal
     * @param to address pool is withdrawn to
     * @param caller address of withdrawl caller
     * @param amount withdrawn tokens amount
     */
    event PoolWithdrawn(address to, address caller, uint256 amount);

    /**
     * @dev check address is not zero-address
     */
    modifier addressNotZero(address addr) {
        require(addr != address(0), "Passed parameter has zero address");
        _;
    }

    /**
     * @dev check amount is not zero
     */
    modifier amountNotZero(uint256 amount) {
        require(amount > 0, "Passed amount is equal to zero");
        _;
    }

    /**
     * @dev check if rewards amount is less than supply limit
     * @param amount amount of rewards is going to be generated
     * @param rewardId reward ID
     */
    modifier underSupplyLimit(uint256 amount, uint256 rewardId) {
        require(
            amount + _rewards[rewardId].distributedRewardAmount <=
                _rewards[rewardId].rewardTotalAmount,
            "Amount surpasses supply limit"
        );
        _;
    }

    /**
     * @dev check if contract has enough hyfi tokens for transfer to user
     * @param amount amount of rewards is going to be generated
     * @param rewardId reward ID
     */
    modifier contractHasEnoughTokens(uint256 amount, uint256 rewardId) {
        require(
            tokenPayoutCalculator(amount, rewardId) <=
                getTokenBalanceInContract(),
            "Contract does not have enough tokens"
        );
        _;
    }

    /**
     * @dev check if rate value is less then 10^decimals (1000000000000000000)
     * @param rate rate value
     */
    modifier limitedExchangeRate(uint256 rate) {
        require(
            rate > 0 && rate <= _tokenDecimals,
            "Rate must be > than 0 and <= to 10^18"
        );
        _;
    }

    /**
     * @dev initializer
     * @param tokenAddress hyfi token ERC-20 smart contract address
     * @param tokenDecimals 10^decimals, 1 whole hyfi token
     * @param exchangeRateHYFI HYFI/USD exchange rate
     */
    function initialize(
        address tokenAddress,
        uint256 tokenDecimals,
        uint256 exchangeRateHYFI
    ) external virtual initializer {
        __AccessControl_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _setupRole(HYFI_REWARD_SUPPLIER, msg.sender);

        _tokenHYFI = IERC20Upgradeable(tokenAddress);
        _exchangeRateHYFI = exchangeRateHYFI;
        _tokenDecimals = tokenDecimals;
    }

    /**
     * @dev set reward info by its ID
     * @param rewardId reward (#4 - HYFI_50, #5 - HYFI_100)
     * @param usdAmount - reward equivalent in USD
     * @param rewardTotalAmount - max amount of rewards
     */
    function setHYFIRewardType(
        uint256 rewardId,
        uint256 usdAmount,
        uint256 rewardTotalAmount
    )
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        amountNotZero(usdAmount)
        amountNotZero(rewardTotalAmount)
    {
        _rewards[rewardId].usdAmount = usdAmount;
        _rewards[rewardId].rewardTotalAmount = rewardTotalAmount;
    }

    /**
     * @dev reveal specific amount of hyfi token rewards
     * @param user user address rewards are reveled for
     * @param amount amount of rewards is going to be revealed
     * @param rewardId reward ID - (#4 - HYFI_50, #5 - HYFI_100)
     */
    function revealRewards(
        address user,
        uint256 amount,
        uint256 rewardId
    )
        external
        underSupplyLimit(amount, rewardId)
        contractHasEnoughTokens(amount, rewardId)
        addressNotZero(user)
        amountNotZero(amount)
        onlyRole(MINTER_ROLE)
    {
        uint256 tokenAmount = tokenPayoutCalculator(amount, rewardId);
        _rewards[rewardId].distributedRewardAmount += amount;
        _rewards[rewardId].userRewardAmount[user] += amount;
        _tokenHYFI.safeTransfer(user, tokenAmount);
        emit RewardsRevealed(user, rewardId, amount);
    }

    /**
     * @dev withdraw hyfi tokens from SC balance
     * @param recipient recipient address
     * @param amount amount of tokens is going to be withdrawn
     */
    function withdrawERC20Tokens(
        address recipient,
        uint256 amount
    )
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        amountNotZero(amount)
        addressNotZero(recipient)
    {
        require(
            IERC20Upgradeable(_tokenHYFI).balanceOf(address(this)) >= amount,
            "Contract does not have enough tokens"
        );
        IERC20Upgradeable(_tokenHYFI).safeTransfer(recipient, amount);

        emit PoolWithdrawn(recipient, msg.sender, amount);
    }

    /**
     * @dev set HYFI token SC address
     * @param newtokenAddress new HYFI token SC address
     */
    function setTokenAddress(
        IERC20Upgradeable newtokenAddress
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _tokenHYFI = newtokenAddress;
    }

    /**
     * @dev set HYFI to USD exchange rate
     * @param newExchangeRate new HYFI exchange rate value
     */
    function setHYFIexchangeRate(
        uint256 newExchangeRate
    )
        external
        onlyRole(HYFI_REWARD_SUPPLIER)
        limitedExchangeRate(newExchangeRate)
    {
        _exchangeRateHYFI = newExchangeRate;
    }

    /**
     * @dev calculate amount of HYFI tokens needed for transfer, by rewards amount and reward ID
     * @param amount amount of rewards
     * @param rewardId reward ID
     * @return return tokens amount
     */
    function tokenPayoutCalculator(
        uint256 amount,
        uint256 rewardId
    ) public view returns (uint256) {
        return
            ((amount * _rewards[rewardId].usdAmount * _tokenDecimals) /
                _exchangeRateHYFI) * _tokenDecimals;
    }

    /**
     * @dev get HYFI tokens amount in the pool (in current SC)
     * @return return HYFI tokens amount
     */
    function getTokenBalanceInContract() public view returns (uint256) {
        return _tokenHYFI.balanceOf(address(this));
    }

    /**
     * @dev get information about reward by its ID
     * @param rewardId reward ID
     * @return return usdAmount
     * @return return rewardTotalAmount
     * @return return distributedRewardAmount
     */
    function getRewardInfo(
        uint256 rewardId
    ) public view returns (uint256, uint256, uint256) {
        return (
            _rewards[rewardId].usdAmount,
            _rewards[rewardId].rewardTotalAmount,
            _rewards[rewardId].distributedRewardAmount
        );
    }

    /**
     * @dev get amount of already distributed rewards for specific reward ID
     * @param rewardId reward ID
     * @return return amount of distributed rewards
     */
    function getRewardDistributedAmount(
        uint256 rewardId
    ) public view returns (uint256) {
        return _rewards[rewardId].distributedRewardAmount;
    }

    /**
     * @dev get amount of already generated rewards for specific reward ID and user
     * @param rewardId reward ID
     * @param user user address
     * @return return amount of generated rewards
     */
    function getUserRewardsAmount(
        address user,
        uint256 rewardId
    ) public view returns (uint256) {
        return _rewards[rewardId].userRewardAmount[user];
    }

    /**
     * @dev get HYFI token SC address
     * @return return address of HYFI token
     */
    function getTokenAddress() public view returns (address) {
        return address(_tokenHYFI);
    }

    /**
     * @dev get HYFI token multiplier (10^decimals, 10^18)
     * @return return multiplier value
     */
    function getTokenDecimals() public view returns (uint256) {
        return _tokenDecimals;
    }

    /**
     * @dev get HYFI to USD exchange rate
     * @return return address of HYFI token
     */
    function getHYFIexchangeRate() public view returns (uint256) {
        return _exchangeRateHYFI;
    }
}