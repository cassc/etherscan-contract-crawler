// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/access/AccessControlEnumerable.sol';
import '../library/IFTokenStandard.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/utils/math/Math.sol';

contract vIDIA is AccessControlEnumerable, IFTokenStandard {
    using SafeERC20 for ERC20;

    uint256 private constant FACTOR = 10**30;
    uint256 private constant FIFTY = 5000; // 50 in basis points
    uint256 private constant ONE_HUNDRED = 10000; // 50 in basis points
    uint256 private constant ONE_MONTH = 86400 * 30;

    // delay for unstaking token
    uint256 public unstakingDelay = 86400 * 14; // 2 weeks in seconds

    // Fees for different actions. All fees denoted in basis points
    uint256 public skipDelayFee = 2000; // initialzed at 20%
    uint256 public cancelUnstakeFee = 200; // initialized at 2%

    uint256 public accumulatedFee;
    uint256 public totalStakedAmt;
    uint256 public rewardPerShare; // (1/T1 + 1/T2 + 1/T3)
    address public immutable underlying;

    struct UserInfo {
        uint256 stakedAmt;
        uint256 unstakeAt;
        uint256 unstakingAmt;
        uint256 lastRewardPerShare;
    }

    bytes32 public constant FEE_SETTER_ROLE = keccak256('FEE_SETTER_ROLE');

    bytes32 public constant DELAY_SETTER_ROLE = keccak256('DELAY_SETTER_ROLE');

    bytes32 public constant WHITELIST_SETTER_ROLE =
        keccak256('WHITELIST_SETTER_ROLE');

    EnumerableSet.AddressSet private whitelistAddresses;

    // user info mapping (user addr => token addr => user info)
    mapping(address => UserInfo) public userInfo;

    // Events

    event Stake(address _from, uint256 amount);

    event Unstake(address _from, uint256 amount);

    event ClaimStaked(address _from, uint256 fee, uint256 withdrawAmt);

    event UpdateSkipDelayFee(uint256 newFee);

    event UpdateCancelUnstakeFee(uint256 newFee);

    event UpdateUnstakingDelay(uint24 newDelay);

    event RemoveFromWhitelist(address account);

    event AddToWhitelist(address account);

    event ClaimUnstaked(address _from, uint256 withdrawAmt);

    event ClaimPendingUnstake(address _from, uint256 fee, uint256 withdrawAmt);

    event CancelPendingUnstake(address _from, uint256 fee, uint256 stakedAmt);

    event ClaimReward(address _from, uint256 amount);

    // In case of emergency we pause functionality and open up emergency withdrawals
    bool public isHalt;

    modifier notHalted() {
        require(!isHalt, 'Contract is halted');
        _;
    }

    modifier onlyWhenHalted() {
        require(isHalt, 'Contract is not halted yet');
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        address _admin,
        address _underlying
    ) AccessControlEnumerable() IFTokenStandard(_name, _symbol, _admin) {
        require(_admin != address(0x0), 'Admin address must not be zero');
        require(
            _underlying != address(0x0),
            'Underlying address must not be zero'
        );
        _setupRole(FEE_SETTER_ROLE, _admin);
        _setupRole(DELAY_SETTER_ROLE, _admin);
        _setupRole(WHITELIST_SETTER_ROLE, _admin);
        underlying = _underlying;

        // Add 0x0 to whitelist so _beforeTokenTransfer doesn't reject mint/burn txs
        // transfers to/from 0x0 fail by default
        EnumerableSet.add(whitelistAddresses, address(0x0));
    }

    function stake(uint256 amount) external notHalted {
        address sender = _msgSender();
        claimReward(sender);
        ERC20(underlying).safeTransferFrom(sender, address(this), amount);
        totalStakedAmt += amount;
        userInfo[sender].stakedAmt += amount;
        _mint(sender, amount);
        emit Stake(sender, amount);
    }

    /** 
     @notice Function for a user unstake tokens and put them in unstaking queue
     @param amount the amount of tokens to unstake from staked tokens
     */
    function unstake(uint256 amount) external notHalted {
        address sender = _msgSender();
        require(
            userInfo[sender].unstakingAmt == 0,
            'User has pending tokens unstaking'
        );
        require(
            userInfo[sender].unstakeAt == 0,
            'User has tokens in unstaking queue'
        );
        claimReward(sender);
        totalStakedAmt -= amount;
        userInfo[sender].stakedAmt -= amount;
        //start unvesting period
        userInfo[sender].unstakeAt = block.timestamp + unstakingDelay;

        userInfo[sender].unstakingAmt = amount;
        burn(userInfo[sender].unstakingAmt);
        emit Unstake(sender, amount);
    }

    /** 
     @notice Function for a user to retrieve underlying tokens after waiting for the unstake delay
     @notice *no* fees required
     @notice For tokens in the unstaking queue, use instantUnstakePending()
     */
    function claimUnstaked() external notHalted {
        address sender = _msgSender();
        //require curr time more than unstaking delay
        require(
            userInfo[sender].unstakingAmt != 0 &&
                block.timestamp > userInfo[sender].unstakeAt,
            'Tokens have not finished vesting'
        );

        uint256 withdrawAmt = userInfo[sender].unstakingAmt;
        userInfo[sender].unstakingAmt = 0;
        userInfo[sender].unstakeAt = 0;
        ERC20(underlying).safeTransfer(sender, withdrawAmt);

        emit ClaimUnstaked(sender, withdrawAmt);
    }

    /** 
     @notice Function for a user to pay fee and receive underlying tokens *NOT* in the unstaking queue
     @notice fees required
     @notice For tokens in the unstaking queue, use claimPendingUnstake()
     @param amount the amount of tokens to instantly withdraw from staked tokens
     */
    function claimStaked(uint256 amount) external notHalted {
        address sender = _msgSender();
        claimReward(sender);

        uint256 fee = (amount * skipDelayFee) / ONE_HUNDRED;
        uint256 withdrawAmt = amount - fee;
        uint256 divisor = totalStakedAmt - userInfo[sender].stakedAmt;

        if (divisor != 0) {
            // mul by FACTOR of 10**30 to reduce truncation
            rewardPerShare += (fee * FACTOR) / divisor;
            userInfo[sender].lastRewardPerShare = rewardPerShare;
        }

        totalStakedAmt -= amount;
        userInfo[sender].stakedAmt -= amount;
        accumulatedFee += fee;

        burn(amount);
        ERC20(underlying).safeTransfer(sender, withdrawAmt);
        emit ClaimStaked(sender, fee, withdrawAmt);
    }

    /** 
     @notice Function for a user to retrieve underlying tokens associated with vidia in the unstaking queue
     @notice fees required
     @dev Requires user to have tokens in the unstake queue which cannot be claimed now
     @param amount the amount of tokens to instantly withdraw from unstake queue
     */
    function claimPendingUnstake(uint256 amount) external notHalted {
        address sender = _msgSender();
        require(
            userInfo[sender].unstakingAmt != 0 &&
                userInfo[sender].unstakeAt > block.timestamp,
            'Can unstake without paying fee'
        );
        claimReward(sender);

        uint256 fee = (amount * skipDelayFee) / ONE_HUNDRED;
        uint256 withdrawAmt = amount - fee;
        uint256 divisor = totalStakedAmt - userInfo[sender].stakedAmt;

        if (divisor != 0) {
            // mul by FACTOR of 10**30 to reduce truncation
            rewardPerShare += (fee * FACTOR) / divisor;
            userInfo[sender].lastRewardPerShare = rewardPerShare;
        }
        accumulatedFee += fee;
        userInfo[sender].unstakingAmt -= amount;
        if (userInfo[sender].unstakingAmt == 0) {
            userInfo[sender].unstakeAt = 0;
        }
        ERC20(underlying).safeTransfer(sender, withdrawAmt);
        emit ClaimPendingUnstake(sender, fee, withdrawAmt);
    }

    /** 
     @notice Function for a user to cancel unstaking process for vidia
     @notice fees required
     @dev Requires user to have tokens in the unstake queue which cannot be claimed now
     @param amount the amount of tokens to cancel unstaking process for
     */
    function cancelPendingUnstake(uint256 amount) external notHalted {
        address sender = _msgSender();
        require(
            userInfo[sender].unstakeAt > block.timestamp,
            'Can restake without paying fee'
        );
        claimReward(sender);

        uint256 fee = (amount * cancelUnstakeFee) / ONE_HUNDRED;
        uint256 stakeAmount = amount - fee;
        uint256 divisor = totalStakedAmt - userInfo[sender].stakedAmt;

        if (divisor != 0) {
            // mul by FACTOR of 10**30 to reduce truncation
            rewardPerShare += (fee * FACTOR) / divisor;
            userInfo[sender].lastRewardPerShare = rewardPerShare;
        }
        accumulatedFee += fee;

        userInfo[sender].unstakingAmt -= amount;
        if (userInfo[sender].unstakingAmt == 0) {
            userInfo[sender].unstakeAt = 0;
        }

        userInfo[sender].stakedAmt += stakeAmount;
        totalStakedAmt += stakeAmount;
        _mint(sender, stakeAmount);
        emit CancelPendingUnstake(sender, fee, stakeAmount);
    }

    // claim reward and reset user's reward sum
    function claimReward(address sender) public {
        uint256 reward = calculateUserReward(sender);
        // reset user's rewards sum
        if (userInfo[sender].lastRewardPerShare != rewardPerShare) {
            userInfo[sender].lastRewardPerShare = rewardPerShare;
        }
        if (reward > 0) {
            // transfer reward to user
            ERC20 claimedTokens = ERC20(underlying);
            claimedTokens.safeTransfer(sender, reward);
            emit ClaimReward(sender, reward);
        }
    }

    /** 
     @notice Update fee levied for instantly unstaking. Fee is in basis points
     @dev Requires fee setter role and fee must be below 5000 basis pts
     @param newFee the new fee
     */
    function updateSkipDelayFee(uint256 newFee)
        external
        onlyRole(FEE_SETTER_ROLE)
    {
        require(newFee <= FIFTY, 'Fee must be less than 50%');
        skipDelayFee = newFee;

        emit UpdateSkipDelayFee(newFee);
    }

    /** 
     @notice Update fee levied for cancelling unstaking. Fee is in basis points
     @dev Requires fee setter role and fee must be below 5000 basis pts
     @param newFee the new fee
     */
    function updateCancelUnstakeFee(uint256 newFee)
        external
        onlyRole(FEE_SETTER_ROLE)
    {
        require(newFee <= FIFTY, 'Fee must be less than 50%');
        cancelUnstakeFee = newFee;

        emit UpdateCancelUnstakeFee(newFee);
    }

    /** 
     @notice Update wait period required for fee-free unvesting. initialized at 2 weeks
     @dev Requires delay setter role and existing wait times will not change
     @param newDelay the new delay
     */
    function updateUnstakingDelay(uint24 newDelay)
        external
        onlyRole(DELAY_SETTER_ROLE)
    {
        require(newDelay <= ONE_MONTH, 'Delay must be <= 1 month');
        unstakingDelay = newDelay;

        emit UpdateUnstakingDelay(newDelay);
    }

    /** 
     @notice Calculates user reward
     @dev formula: amount * (global_reward_sum - user_reward_sum) / 10**30
     @dev we perform div 10**30 as rewardsum is inflated by 10**30 to reduce truncation
     @return uint256 amount of underlying tokens the user has earned from fees
     */
    function calculateUserReward(address user) public view returns (uint256) {
        return
            (userInfo[user].stakedAmt *
                (rewardPerShare - userInfo[user].lastRewardPerShare)) / FACTOR;
    }

    /** 
     @notice Adds an address to the transfer whitelist
     @dev requires whitelist setter role
     @param account is the address to add to whitelist
     @return boolean. True = account was added, False = account already exists in set
     */
    function addToWhitelist(address account)
        external
        onlyRole(WHITELIST_SETTER_ROLE)
        returns (bool)
    {
        emit AddToWhitelist(account);
        return EnumerableSet.add(whitelistAddresses, account);
    }

    /** 
     @notice Removes an address to the transfer whitelist
     @dev requires whitelist setter role
     @param account is the address to remove from whitelist
     @return boolean. True = account was removed, False = account doesnt exist in set
     */
    function removeFromWhitelist(address account)
        external
        onlyRole(WHITELIST_SETTER_ROLE)
        returns (bool)
    {
        require(
            ERC20(address(this)).balanceOf(account) == 0,
            '0 token balance required to remove from whitelist'
        );

        emit RemoveFromWhitelist(account);

        return EnumerableSet.remove(whitelistAddresses, account);
    }

    /** 
     @notice Getter for all transfer whitelisted addresses
     @return Array of all transfer whitelisted addresses
     */
    function getAllWhitelistedAddrs() external view returns (address[] memory) {
        return EnumerableSet.values(whitelistAddresses);
    }

    /**
     @notice Overriding _beforeTokenTransfer in ERC20
     @dev metatx caller will never be whitelisted, no need to worry about _msgSender() 
     @param from the address tokens are taken from
     @param to the address to send tokens to
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256
    ) internal view override {
        require(
            EnumerableSet.contains(whitelistAddresses, from) ||
                EnumerableSet.contains(whitelistAddresses, to),
            'Origin and dest address not in whitelist'
        );
    }

    /** 
     @notice function to halt contract and allow emergency withdrawals
     @dev only can be called by contract admin
     */
    function halt() external onlyRole(DEFAULT_ADMIN_ROLE) {
        isHalt = true;
    }

    /** 
     @notice function to allow users to withdraw underlying tokens not in unstaking queue
     @dev only can be called when contract is halted
     */
    function emergencyWithdrawStaked() external onlyWhenHalted {
        uint256 availAmt = ERC20(underlying).balanceOf(address(this));
        uint256 withdrawAmt = userInfo[_msgSender()].stakedAmt;
        userInfo[_msgSender()].stakedAmt = 0;
        ERC20(underlying).safeTransfer(
            _msgSender(),
            Math.min(availAmt, withdrawAmt)
        );
    }

    /** 
     @notice function to allow users to withdraw underlying tokens in unstaking queue 
     @dev only can be called when contract is halted
     */
    function emergencyWithdrawUnstaking() external onlyWhenHalted {
        uint256 availAmt = ERC20(underlying).balanceOf(address(this));
        uint256 withdrawAmt = userInfo[_msgSender()].unstakingAmt;
        userInfo[_msgSender()].unstakingAmt = 0;
        ERC20(underlying).safeTransfer(
            _msgSender(),
            Math.min(availAmt, withdrawAmt)
        );
    }

    /** 
     @notice function for admin to withdraw tokens other than underlying 
     @dev used in emergency when users send wrong tokens into this contract
     @dev only can be called by contract admin
     */
    function emergencyWithdrawOtherTokens(ERC20 token, address to)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(address(token) != underlying, 'can only withdraw other ERC20s');
        require(address(token) != address(this), 'cannot withdraw vIDIA');
        token.safeTransfer(to, token.balanceOf(address(this)));
    }

    /** 
     @notice msg.sender for EIP2771 meta transactions. Parses out original msg.sender when transaction is sent by relayer
     @return address of msg.sender
     */
    function _msgSender()
        internal
        view
        override(IFTokenStandard, Context)
        returns (address)
    {
        return ERC2771ContextUpdateable._msgSender();
    }

    /** 
     @notice msg.data for EIP2771 meta transactions. Parses out original msg.data when transaction is sent by relayer
     @return bytes of msg.data
     */
    function _msgData()
        internal
        view
        override(IFTokenStandard, Context)
        returns (bytes calldata)
    {
        return ERC2771ContextUpdateable._msgData();
    }

    //// EIP1363 payable token
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(AccessControlEnumerable, IFTokenStandard)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}