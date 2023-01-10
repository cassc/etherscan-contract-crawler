// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./helpers/IStaking.sol";
import "./helpers/TimeConstants.sol";

import "./Controller.sol";
import "./helpers/Util.sol";
import "./StakingStorage.sol";
import "./helpers/PermissionControl.sol";

/**
 * @dev ASM Genome Mining - Staking Logic contract
 */

contract Staking is IStaking, Util, PermissionControl, Pausable {
    using SafeERC20 for IERC20;
    using ECDSA for bytes32;

    bool private _initialized = false;

    uint256 public constant ASTO_TOKEN_ID = 0;
    uint256 public constant LP_TOKEN_ID = 1;

    uint256 public lbaStakeTime;
    address private _signer;

    /**
     * `_token`:  tokenId => token contract address
     * `_token`:  tokenId => token name
     * `_storage`:  tokenId => storage contract address
     *
     * IDs: 0 for ASTO, 1 for LP tokens, see `init()` below
     */
    mapping(uint256 => IERC20) private _token;
    mapping(uint256 => string) private _tokenName;
    mapping(uint256 => StakingStorage) private _storage;
    mapping(uint256 => uint256) public totalStakedAmount;
    mapping(address => bool) public lbaMigrated;

    constructor(
        address controller,
        address signer,
        uint256 _lbaStakeTime
    ) {
        if (!_isContract(controller)) revert InvalidInput(INVALID_CONTROLLER);
        _signer = signer;
        lbaStakeTime = _lbaStakeTime;
        _grantRole(CONTROLLER_ROLE, controller);
        _pause();
    }

    /** ----------------------------------
     * ! Administration          | dao
     * ----------------------------------- */

    /**
     * @notice Withdraw tokens left in the contract to specified address
     * @param tokenId - ID of token to stake
     * @param recipient recipient of the transfer
     * @param amount Token amount to withdraw
     */
    function withdraw(
        uint256 tokenId,
        address recipient,
        uint256 amount
    ) external onlyRole(DAO_ROLE) {
        if (!_isContract(address(_token[tokenId]))) revert InvalidInput(WRONG_TOKEN);
        if (address(recipient) == address(0)) revert InvalidInput(WRONG_ADDRESS);
        if (_token[tokenId].balanceOf(address(this)) < amount) revert InvalidInput(INSUFFICIENT_BALANCE);

        _token[tokenId].safeTransfer(recipient, amount);
    }

    /**
     * @notice Update LP stake time used for LBA migration
     * @dev This function can only to called from contracts or wallets with DAO_ROLE
     * @param _time LBA LP stake time, it should be the same as lpTokenReleaseTime in LBA contract
     */
    function setLBAStakeTime(uint256 _time) external onlyRole(DAO_ROLE) {
        lbaStakeTime = _time;
    }

    /**
     * @notice Update token contract address
     * @dev This function can only to called from contracts or wallets with DAO_ROLE
     * @param tokenId The token id to update
     * @param tokenAddress New contract address for the token
     */
    function setTokenAddress(uint256 tokenId, address tokenAddress) external onlyRole(DAO_ROLE) {
        if (!_isContract(tokenAddress)) revert InvalidInput(WRONG_TOKEN);
        _token[tokenId] = IERC20(tokenAddress);
    }

    /**
     * @notice Set signer to `signer`
     * @dev This function can only to called from contracts or wallets with DAO_ROLE
     * @param signer The new signer address to update
     */
    function setSigner(address signer) external onlyRole(DAO_ROLE) {
        _signer = signer;
    }

    /** ----------------------------------
     * ! Administration       | CONTROLLER
     * ----------------------------------- */

    /**
     * @dev Setting up persmissions for this contract:
     * @dev only DAO contract is allowed to call admin functions
     * @dev only controller is allowed to update permissions - to reduce amount of DAO votings
     *
     * @param astoToken ASTO Token contract address
     * @param lpToken LP Token contract address
     * @param astoStorage ASTO staking storage contract address
     * @param lpStorage LP staking storage contract address
     */
    function init(
        address dao,
        IERC20 astoToken,
        address astoStorage,
        IERC20 lpToken,
        address lpStorage,
        uint256 totalStakedAsto,
        uint256 totalStakedLp
    ) external onlyRole(CONTROLLER_ROLE) {
        if (!_initialized) {
            _token[0] = astoToken;
            _storage[0] = StakingStorage(astoStorage);
            _tokenName[0] = "ASTO";

            _token[1] = lpToken;
            _storage[1] = StakingStorage(lpStorage);
            _tokenName[1] = "ASTO/USDC Uniswap V2 LP";

            _clearRole(DAO_ROLE);
            _grantRole(DAO_ROLE, dao);

            _clearRole(MULTISIG_ROLE);
            _grantRole(MULTISIG_ROLE, dao);

            totalStakedAmount[ASTO_TOKEN_ID] = totalStakedAsto;
            totalStakedAmount[LP_TOKEN_ID] = totalStakedLp;

            _initialized = true;
        }
    }

    /**
     * @dev Update the DAO contract address
     * @dev only controller is allowed to set new DAO contract
     */
    function setDao(address newDao) external onlyRole(CONTROLLER_ROLE) {
        _clearRole(DAO_ROLE);
        _grantRole(DAO_ROLE, newDao);
    }

    /**
     * @dev Update the Controller contract address
     * @dev only controller is allowed to call this function
     */
    function setController(address newController) external onlyRole(CONTROLLER_ROLE) {
        _clearRole(CONTROLLER_ROLE);
        _grantRole(CONTROLLER_ROLE, newController);
    }

    /**
     * @dev Pause the contract
     * @dev only controller is allowed to call this function
     */
    function pause() external onlyRole(CONTROLLER_ROLE) {
        _pause();
    }

    /**
     * @dev Unpause the contract
     * @dev only controller is allowed to call this function
     */
    function unpause() external onlyRole(CONTROLLER_ROLE) {
        _unpause();
    }

    /** ----------------------------------
     * ! Business logic
     * ----------------------------------- */

    /**
     * @notice Save user's stake
     *
     * @notice Staking is a process of locking your tokens in this contract.
     * @notice Details of the stake are to be stored and used for calculations
     * @notice what time your tokens are stay staked.
     *
     * @dev Prerequisite:
     * @dev - amount of tokens to stake should be approved by user.
     * @dev - this contract should have a `CONSUMER_ROLE` to call
     * @dev   the storage's `updateHistory()` function.
     *
     * @dev Depending on tokenId passed, it:
     * @dev 1. transfers tokens from user to this contract
     * @dev 2. calls an appropriate token storage and saves time and amount of stake.
     *
     * @dev Emit `UnStaked` event on success: with token name, user address, timestamp, amount
     *
     * @param tokenId - ID of token to stake
     * @param amount - amount of tokens to stake
     */
    function stake(uint256 tokenId, uint256 amount) external whenNotPaused {
        if (tokenId > 1) revert InvalidInput(WRONG_TOKEN);
        if (amount == 0) revert InvalidInput(WRONG_AMOUNT);
        address user = msg.sender;
        uint256 tokenBalance = _token[tokenId].balanceOf(user);
        if (amount > tokenBalance) revert InvalidInput(INSUFFICIENT_BALANCE);

        _token[tokenId].safeTransferFrom(user, address(this), amount);

        uint256 lastStakeId = _storage[tokenId].getUserLastStakeId(user);
        uint256 stakeBalance = (_storage[tokenId].getStake(user, lastStakeId)).amount;
        uint256 newAmount = stakeBalance + amount;
        _storage[tokenId].updateHistory(user, newAmount);
        totalStakedAmount[tokenId] += amount;

        emit Staked(_tokenName[tokenId], user, block.timestamp, amount);
    }

    /**
     * @notice Stake on behalf of `staker`.
     * @notice This function can be used for auto-staking from consumer contracts on behalf of users
     * @param staker - User wallet address. It should be the wallet which a consumer contract or account stake tokens for
     * @param tokenId - ID of token to stake
     * @param amount - amount of tokens to stake
     */
    function stakeFor(
        address staker,
        uint256 tokenId,
        uint256 amount
    ) external whenNotPaused onlyRole(CONSUMER_ROLE) {
        if (tokenId > 1) revert InvalidInput(WRONG_TOKEN);
        if (amount == 0) revert InvalidInput(WRONG_AMOUNT);

        uint256 tokenBalance = _token[tokenId].balanceOf(msg.sender);
        if (amount > tokenBalance) revert InvalidInput(INSUFFICIENT_BALANCE);

        _token[tokenId].safeTransferFrom(msg.sender, address(this), amount);

        uint256 lastStakeId = _storage[tokenId].getUserLastStakeId(staker);
        uint256 stakeBalance = (_storage[tokenId].getStake(staker, lastStakeId)).amount;
        uint256 newAmount = stakeBalance + amount;
        _storage[tokenId].updateHistory(staker, newAmount);
        totalStakedAmount[tokenId] += amount;

        emit Staked(_tokenName[tokenId], staker, block.timestamp, amount);
    }

    /**
     * @notice Migrate user's LBA LP tokens to staking contract
     * @param amount The LP token amount to be migrated, it should be the same amount with claimed LP tokens from LBA contract
     * @param signature Signature will be used for user and amount verification.
              It should be generated from backend with correct LP token amount from Transfer event.
     */
    function migrateAuctionLP(uint256 amount, bytes calldata signature) external whenNotPaused {
        address user = msg.sender;
        if (lbaMigrated[user]) revert InvalidInput(ALREADY_MIGRATED);
        if (!validateSignature(_hash(msg.sender, amount), signature)) revert InvalidInput(INVALID_SIGNATURE);

        _token[LP_TOKEN_ID].safeTransferFrom(user, address(this), amount);
        _storage[LP_TOKEN_ID].migrateLBAHistory(user, amount, lbaStakeTime);

        lbaMigrated[user] = true;
        totalStakedAmount[LP_TOKEN_ID] += amount;

        emit Staked(_tokenName[LP_TOKEN_ID], user, lbaStakeTime, amount);
    }

    /**
     * @notice Migrate users' stake history from the old contract after upgrading the Staking contract to a new version
     * @dev This function can only to called from contracts or wallets with DAO_ROLE
     * @param tokenId The token id for migration. `0` for ASTO and `1` for LP token.
     * @param addresses The list of user wallet address to be migrated.
     */
    function migrateHistory(uint256 tokenId, address[] calldata addresses) external onlyRole(DAO_ROLE) {
        _storage[tokenId].migrateStakeHistory(addresses);
    }

    /**
     * @notice Encode arguments to generate a hash, which will be used for validating signatures
     * @dev This function can only be called inside the contract
     * @param user The user wallet address, to verify the signature can only be used by the wallet
     * @param amount The LP token amount to be migrated
     * @return Encoded hash
     */
    function _hash(address user, uint256 amount) internal pure returns (bytes32) {
        return keccak256(abi.encode(user, amount));
    }

    /**
     * @notice Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     * @dev This function can only be called inside the contract
     * @param hash The encoded hash used for signature
     * @param token The signature passed from the caller
     * @return The recovered address
     */
    function _recover(bytes32 hash, bytes memory token) internal pure returns (address) {
        return hash.toEthSignedMessageHash().recover(token);
    }

    /**
     * @notice To validate the `signature` is signed by the _signer
     * @param hash The encoded hash used for signature
     * @param token The signature passed from the caller
     * @return Verification result
     */
    function validateSignature(bytes32 hash, bytes memory token) public view returns (bool) {
        return (_recover(hash, token) == _signer);
    }

    /**
     * @notice Unstake user's stake
     *
     * @notice Unstaking is a process of getting back previously staked tokens.
     * @notice Users can unlock their tokens any time.
     *
     * @dev No prerequisites
     * @dev Users can unstake only their own, previously staked  tokens
     * @dev Emit `UnStaked` event on success: with token name, user address, timestamp, amount
     *
     * @param tokenId - ID of token to stake
     * @param amount - amount of tokens to stake
     */
    function unstake(uint256 tokenId, uint256 amount) external whenNotPaused {
        if (!_isContract(address(_token[tokenId]))) revert InvalidInput(WRONG_TOKEN);
        if (amount == 0) revert InvalidInput(WRONG_AMOUNT);

        address user = msg.sender;
        uint256 id = _storage[tokenId].getUserLastStakeId(user);
        if (id == 0) revert InvalidInput(NO_STAKES);
        uint256 userBalance = (_storage[tokenId].getStake(user, id)).amount;
        if (amount > userBalance) revert InvalidInput(INSUFFICIENT_BALANCE);

        uint256 newAmount = userBalance - amount;
        _storage[tokenId].updateHistory(user, newAmount);
        totalStakedAmount[tokenId] -= amount;

        _token[tokenId].safeTransfer(user, amount);

        emit UnStaked(_tokenName[tokenId], user, block.timestamp, amount);
    }

    /**
     * @notice Returns the total amount of tokens staked by all users
     *
     * @param tokenId ASTO - 0, LP - 1
     * @return amount of tokens staked in the contract, uint256
     */
    function getTotalValueLocked(uint256 tokenId) external view returns (uint256) {
        return totalStakedAmount[tokenId];
    }

    /** ----------------------------------
     * ! Getters
     * ----------------------------------- */

    /**
     * @notice Returns address of the token storage contract
     *
     * @param tokenId ASTO - 0, LP - 1
     * @return address of the token storage contract
     */
    function getStorageAddress(uint256 tokenId) external view returns (address) {
        return address(_storage[tokenId]);
    }

    /**
     * @notice Returns address of the token contract
     *
     * @param tokenId ASTO - 0, LP - 1
     * @return address of the token contract
     */
    function getTokenAddress(uint256 tokenId) external view returns (address) {
        return address(_token[tokenId]);
    }

    /**
     * @notice Returns the staking history of user
     *
     * @param tokenId ASTO - 0, LP - 1
     * @param addr user wallet address
     * @param endTime until what time tokens were staked
     * @return sorted list of stakes, for each stake: { time, amount },
     *         starting with earliest
     */
    function getHistory(
        uint256 tokenId,
        address addr,
        uint256 endTime
    ) external view returns (Stake[] memory) {
        return _storage[tokenId].getHistory(addr, endTime);
    }
}